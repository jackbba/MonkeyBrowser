import UIKit

class ScriptsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private var tableView: UITableView!
    private var emptyLabel: UILabel!
    private var scripts: [UserScript] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Tampermonkey Scripts"
        view.backgroundColor = .systemBackground
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadScripts()
    }

    private func setupUI() {
        emptyLabel = UILabel()
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.text = "No scripts installed\nTap + to import scripts"
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.numberOfLines = 0
        view.addSubview(emptyLabel)

        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ScriptCell")
        view.addSubview(tableView)

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addScript)
        )

        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadScripts() {
        scripts = UserScriptEngine.shared.getAllScripts()
        emptyLabel.isHidden = !scripts.isEmpty
        tableView.reloadData()
    }

    @objc private func addScript() {
        let alert = UIAlertController(title: "Import Script", message: "Supports Tampermonkey/Greasemonkey format", preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "From Clipboard", style: .default) { [weak self] _ in
            self?.importFromClipboard()
        })

        alert.addAction(UIAlertAction(title: "From URL", style: .default) { [weak self] _ in
            self?.importFromURL()
        })

        alert.addAction(UIAlertAction(title: "Paste Code", style: .default) { [weak self] _ in
            self?.importFromCode()
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func importFromClipboard() {
        guard let code = UIPasteboard.general.string else {
            showAlert("Clipboard is empty")
            return
        }
        processScript(code)
    }

    private func importFromURL() {
        let alert = UIAlertController(title: "Script URL", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "https://example.com/script.user.js" }
        alert.addAction(UIAlertAction(title: "Download", style: .default) { [weak self] _ in
            guard let urlString = alert.textFields?.first?.text,
                  let url = URL(string: urlString) else { return }
            self?.downloadScript(from: url)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func importFromCode() {
        let alert = UIAlertController(title: "Paste Script Code", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Paste Tampermonkey script code here..." }
        alert.addAction(UIAlertAction(title: "Install", style: .default) { [weak self] _ in
            guard let code = alert.textFields?.first?.text else { return }
            self?.processScript(code)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func downloadScript(from url: URL) {
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let data = data, error == nil,
                  let code = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async {
                    self?.showAlert("Download failed")
                }
                return
            }
            DispatchQueue.main.async {
                self?.processScript(code)
            }
        }
        task.resume()
    }

    private func processScript(_ code: String) {
        let metadata = UserScriptMetadata.parse(from: code)
        UserScriptEngine.shared.installScript(code, metadata: metadata)
        loadScripts()
        showAlert("Script installed: \(metadata.name)")
    }

    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scripts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScriptCell", for: indexPath)
        let script = scripts[indexPath.row]

        var config = cell.defaultContentConfiguration()
        config.text = script.name
        config.secondaryText = script.description.isEmpty ? script.author : script.description
        cell.contentConfiguration = config

        let toggle = UISwitch()
        toggle.isOn = script.isEnabled
        toggle.tag = indexPath.row
        toggle.addTarget(self, action: #selector(toggleScript(_:)), for: .valueChanged)
        cell.accessoryView = toggle

        return cell
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
        -> UISwipeActionsConfiguration? {

        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            guard let self = self else { return }
            let script = self.scripts[indexPath.row]
            UserScriptEngine.shared.removeScript(script.id)
            self.scripts.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            completion(true)
        }

        return UISwipeActionsConfiguration(actions: [delete])
    }

    @objc private func toggleScript(_ sender: UISwitch) {
        let script = scripts[sender.tag]
        UserScriptEngine.shared.toggleScript(script.id, enabled: sender.isOn)
    }
}
