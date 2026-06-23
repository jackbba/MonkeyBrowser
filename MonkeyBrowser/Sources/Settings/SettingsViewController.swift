import UIKit

class SettingsViewController: UITableViewController {

    private let settings: [(section: String, items: [SettingItem])] = [
        ("General", [
            SettingItem(title: "Homepage", icon: "house", type: .text),
            SettingItem(title: "Search Engine", icon: "magnifyingglass", type: .text),
            SettingItem(title: "Private Mode", icon: "eye.slash", type: .toggle)
        ]),
        ("Appearance", [
            SettingItem(title: "Theme", icon: "paintbrush", type: .text),
            SettingItem(title: "Font Size", icon: "textformat.size", type: .text),
            SettingItem(title: "Ad Block", icon: "shield", type: .toggle)
        ]),
        ("Advanced", [
            SettingItem(title: "JavaScript", icon: "chevron.left.forwardslash.chevron.right", type: .toggle),
            SettingItem(title: "Desktop Mode", icon: "desktopcomputer", type: .toggle),
            SettingItem(title: "Developer Tools", icon: "wrench", type: .toggle)
        ]),
        ("About", [
            SettingItem(title: "Version", icon: "info.circle", type: .text),
            SettingItem(title: "License", icon: "doc.text", type: .text),
            SettingItem(title: "Feedback", icon: "envelope", type: .text)
        ])
    ]

    private struct SettingItem {
        let title: String
        let icon: String
        let type: SettingType

        enum SettingType {
            case text
            case toggle
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        tableView = UITableView(frame: .zero, style: .insetGrouped)
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return settings.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings[section].items.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return settings[section].section
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ??
            UITableViewCell(style: .default, reuseIdentifier: "Cell")
        let item = settings[indexPath.section].items[indexPath.row]

        var config = cell.defaultContentConfiguration()
        config.text = item.title
        config.image = UIImage(systemName: item.icon)
        cell.contentConfiguration = config

        switch item.type {
        case .toggle:
            let toggle = UISwitch()
            toggle.isOn = UserDefaults.standard.bool(forKey: item.title)
            toggle.tag = indexPath.section * 100 + indexPath.row
            toggle.addTarget(self, action: #selector(toggleChanged(_:)), for: .valueChanged)
            cell.accessoryView = toggle
            cell.selectionStyle = .none
        case .text:
            cell.accessoryType = .disclosureIndicator
        }

        return cell
    }

    @objc private func toggleChanged(_ sender: UISwitch) {
        let section = sender.tag / 100
        let row = sender.tag % 100
        let key = settings[section].items[row].title
        UserDefaults.standard.set(sender.isOn, forKey: key)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = settings[indexPath.section].items[indexPath.row]

        if item.title == "Version" {
            showVersion()
        } else if item.title == "Homepage" {
            setHomepage()
        } else if item.title == "Search Engine" {
            setSearchEngine()
        }
    }

    private func showVersion() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let alert = UIAlertController(
            title: "MonkeyBrowser",
            message: "Version \(version)\nTampermonkey + VLC Browser",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func setHomepage() {
        let alert = UIAlertController(title: "Set Homepage", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = UserDefaults.standard.url(forKey: "homepage")?.absoluteString ?? "https://www.google.com"
        }
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            if let text = alert.textFields?.first?.text,
               let url = URL(string: text) {
                UserDefaults.standard.set(url, forKey: "homepage")
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func setSearchEngine() {
        let alert = UIAlertController(title: "Search Engine", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Google", style: .default))
        alert.addAction(UIAlertAction(title: "Bing", style: .default))
        alert.addAction(UIAlertAction(title: "Baidu", style: .default))
        alert.addAction(UIAlertAction(title: "DuckDuckGo", style: .default))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}
