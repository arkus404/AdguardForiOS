//
// This file is part of Adguard for iOS (https://github.com/AdguardTeam/AdguardForiOS).
// Copyright © Adguard Software Limited. All rights reserved.
//
// Adguard for iOS is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Adguard for iOS is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Adguard for iOS. If not, see <http://www.gnu.org/licenses/>.
//

import UIKit
import DnsAdGuardSDK

final class CompanyDetailedController: UITableViewController {

    // MARK: - Outlets
    @IBOutlet weak var titleLabel: ThemableLabel!

    @IBOutlet weak var requestsNumberLabel: ThemableLabel!
    @IBOutlet weak var encryptedNumberLabel: UILabel!

    @IBOutlet weak var searchBar: UISearchBar!

    @IBOutlet weak var placeHolderLabel: ThemableLabel!

    @IBOutlet weak var tableHeaderView: UIView!
    @IBOutlet var tableFooterView: UIView!
    @IBOutlet var sectionHeaderView: UIView!

    @IBOutlet weak var recentActivityLabel: ThemableLabel!

    @IBOutlet var themableButtons: [ThemableButton]!
    @IBOutlet var themableLabels: [ThemableLabel]!
    @IBOutlet weak var filterButton: UIButton!

    // MARK: - Services

    private let theme: ThemeServiceProtocol = ServiceLocator.shared.getService()!
    private let configuration: ConfigurationServiceProtocol = ServiceLocator.shared.getService()!
    private let dnsTrackers: DnsTrackersProviderProtocol = ServiceLocator.shared.getService()!
    private let domainParserService: DomainParserServiceProtocol = ServiceLocator.shared.getService()!
    private let dnsProtection: DnsProtectionProtocol = ServiceLocator.shared.getService()!

    // MARK: - Notifications

    private var advancedModeObserver: NotificationToken?
    private var keyboardShowToken: NotificationToken?

    // MARK: - Public variables

    // TODO: - It's a crutch to get link of `ActivityViewController`
    weak var activityVC: DnsRequestDetailsContainerControllerDelegate?
    var statisticsPeriod: StatisticsPeriod?
    var record: CompanyRequestsRecord?

    // MARK: - Private variables
    private let requestsModel: DnsRequestLogViewModel
    private var selectedRecord: DnsLogRecord?

    private let activityTableViewCellReuseId = "ActivityTableViewCellId"
    private let showDnsContainerSegueId = "showDnsContainer"

    private var titleInNavBarIsShown = false

    required init?(coder: NSCoder) {
        self.requestsModel = DnsRequestLogViewModel(
            dnsTrackers: ServiceLocator.shared.getService()!,
            dnsStatistics: ServiceLocator.shared.getService()!,
            dnsProtection: ServiceLocator.shared.getService()!,
            domainParser: ServiceLocator.shared.getService()!,
            logRecordHelper: ServiceLocator.shared.getService()!,
            dnsConfigAssistant: ServiceLocator.shared.getService()!
        )
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        updateTheme()
        setupTableView()
        addObservers()
        setupBackButton()
        titleLabel.text = record?.company

        requestsModel.delegate = self
        if let period = statisticsPeriod, let domains = record?.domains {
            requestsModel.obtainRecords(for: period, domains: domains)
        }

        let requestsCount = record?.requests ?? 0
        let encryptedCount = record?.encrypted ?? 0

        filterButton.isHidden = !configuration.advancedMode

        requestsNumberLabel.text = String.formatNumberByLocale(NSNumber(integerLiteral: requestsCount))
        encryptedNumberLabel.text = String.formatNumberByLocale(NSNumber(integerLiteral: encryptedCount))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let height = tableHeaderView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        var headerFrame = tableHeaderView.frame

        if height != headerFrame.size.height {
            headerFrame.size.height = height
            tableHeaderView.frame = headerFrame
            tableView.tableHeaderView = tableHeaderView
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showDnsContainerSegueId {
            if let controller = segue.destination as? DnsRequestDetailsContainerController, let record = selectedRecord {
                let helper: DnsLogRecordHelper = ServiceLocator.shared.getService()!
                let model = DnsRequestDetailsViewModel(logRecord: record, helper: helper, dnsFilters: dnsProtection)
                controller.model = model
                controller.delegate = self
            }
        }
    }

    // MARK: - Actions

    @IBAction func infoAction(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            let title = String.localizedString("requests_info_alert_title")
            let message = String.localizedString("requests_info_alert_message")
            ACSSystemUtils.showSimpleAlert(for: self, withTitle: title, message: message)
        case 1:
            let title = String.localizedString("encrypted_info_alert_title")
            let message = String.localizedString("encrypted_info_alert_message")
            ACSSystemUtils.showSimpleAlert(for: self, withTitle: title, message: message)
        default:
            return
        }
    }

    @IBAction func changeRequestsTypeAction(_ sender: UIButton) {
        showGroupsAlert(sender)
    }

    // MARK: - UITableViewDataSource, UITableViewDelegate

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return sectionHeaderView
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        theme.setupLabel(placeHolderLabel)
        return requestsModel.records.count == 0 ? tableFooterView : UIView()
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if requestsModel.records.count == 0 {
            let isBigScreen = traitCollection.verticalSizeClass == .regular && traitCollection.horizontalSizeClass == .regular
            return isBigScreen ? 200.0 : 150.0
        }
        return 0.01
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return requestsModel.records.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: activityTableViewCellReuseId) as? ActivityTableViewCell {
            let record = requestsModel.records[indexPath.row]
            cell.advancedMode = configuration.advancedMode
            cell.theme = theme
            cell.record = record
            return cell
        }
        return UITableViewCell()
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y

        if offset > titleLabel.frame.maxY && !titleInNavBarIsShown {
            animateShowingTitleInNavBar(record?.company)
            titleInNavBarIsShown = true
            return
        }

        if offset < titleLabel.frame.maxY && titleInNavBarIsShown {
            animateHidingTitleInNavBar()
            titleInNavBarIsShown = false
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let record = requestsModel.records[indexPath.row]
        selectedRecord = record
        performSegue(withIdentifier: showDnsContainerSegueId, sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - Private methods

    private func addObservers(){
        keyboardShowToken = NotificationCenter.default.observe(name: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { [weak self] (notification) in
            self?.keyboardWillShow()
        }

        advancedModeObserver = NotificationCenter.default.observe(name: .advancedModeChanged, object: nil, queue: .main, using: { [weak self] _ in
            self?.observeAdvancedMode()
        })

        requestsModel.recordsObserver = { [weak self] records in
            DispatchQueue.asyncSafeMain { [weak self] in
                guard let self = self else { return }

                self.refreshControl?.endRefreshing()

                self.tableView.reloadData()
                if self.requestsModel.records.isEmpty {
                    self.tableView.scrollRectToVisible(self.tableFooterView.frame, animated: true)
                }
            }
        }
    }

    private func keyboardWillShow() {
        DispatchQueue.main.async {[weak self] in
            let isEmpty = self?.tableView.numberOfRows(inSection: 0) == 0
            if !isEmpty {
                self?.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            }
        }
    }

    private func observeAdvancedMode(){
        DispatchQueue.main.async {[weak self] in
            guard let self = self else { return }
            self.tableView.reloadData()
            self.filterButton.isHidden = !self.configuration.advancedMode
        }
    }

    private func setupTableView(){
        let nib = UINib.init(nibName: "ActivityTableViewCell", bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: activityTableViewCellReuseId)
        refreshControl?.addTarget(self, action: #selector(updateTableView(sender:)), for: .valueChanged)
    }

    private func showGroupsAlert(_ sender: UIButton) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .deviceAlertStyle)

        let allRequestsAction = UIAlertAction(title: String.localizedString("all_requests_alert_action"), style: .default) {[weak self] _ in
            guard let self = self else { return }
            self.requestsModel.displayedStatisticsType = .allRequests
            if let period = self.statisticsPeriod, let domains = self.record?.domains {
                self.requestsModel.obtainRecords(for: period, domains: domains)
            }
            alert.dismiss(animated: true, completion: nil)
        }

        let blockedOnlyAction = UIAlertAction(title: String.localizedString("blocked_only_alert_action"), style: .default) {[weak self] _ in
            guard let self = self else { return }
            self.requestsModel.displayedStatisticsType = .blockedRequests
            if let period = self.statisticsPeriod, let domains = self.record?.domains {
                self.requestsModel.obtainRecords(for: period, domains: domains)
            }
            alert.dismiss(animated: true, completion: nil)
        }

        let allowedOnlyAction = UIAlertAction(title: String.localizedString("allowed_only_alert_action"), style: .default) {[weak self] _ in
            guard let self = self else { return }
            self.requestsModel.displayedStatisticsType = .allowedRequests
            if let period = self.statisticsPeriod, let domains = self.record?.domains {
                self.requestsModel.obtainRecords(for: period, domains: domains)
            }
            alert.dismiss(animated: true, completion: nil)
        }

        let cancelAction = UIAlertAction(title: String.localizedString("common_action_cancel"), style: .cancel) { _ in
            alert.dismiss(animated: true, completion: nil)
        }

        alert.addAction(allRequestsAction)
        alert.addAction(blockedOnlyAction)
        alert.addAction(allowedOnlyAction)
        alert.addAction(cancelAction)

        present(alert, animated: true)
    }

    @objc private final func updateTableView(sender: UIRefreshControl) {
        if let period = statisticsPeriod, let domains = record?.domains {
            requestsModel.obtainRecords(for: period, domains: domains)
        }
    }
}

// MARK: - UISearchBarDelegate

extension CompanyDetailedController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
    }

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        UIView.animate(withDuration: 0.5) {
            searchBar.showsCancelButton = true
        }
        return true
    }

    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        UIView.animate(withDuration: 0.5) {
            searchBar.showsCancelButton = false
        }
        return true
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        UIView.animate(withDuration: 0.5) {
            searchBar.resignFirstResponder()
        }
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        requestsModel.searchString = searchText
    }
}

// MARK: - DnsRequestsDelegateProtocol

extension CompanyDetailedController: DnsRequestsDelegateProtocol {
    func requestsCleared() {
        DispatchQueue.asyncSafeMain { [weak self] in
            self?.tableView.reloadData()
        }
    }
}

// MARK: - DnsRequestDetailsContainerControllerDelegate

extension CompanyDetailedController: DnsRequestDetailsContainerControllerDelegate {
    func userStatusChanged() {
        requestsModel.updateUserStatuses()
        activityVC?.userStatusChanged()
        DispatchQueue.asyncSafeMain { [weak self] in
            self?.tableView.reloadData()
        }
    }
}

extension CompanyDetailedController: ThemableProtocol {
    func updateTheme(){
        tableView.reloadData()
        view.backgroundColor = theme.backgroundColor
        refreshControl?.tintColor = theme.grayTextColor
        tableHeaderView.backgroundColor = theme.backgroundColor
        sectionHeaderView.backgroundColor = theme.backgroundColor
        theme.setupTable(tableView)
        theme.setupSearchBar(searchBar)
        theme.setupLabels(themableLabels)
        theme.setupButtons(themableButtons)
        theme.setupLabel(recentActivityLabel)
    }
}
