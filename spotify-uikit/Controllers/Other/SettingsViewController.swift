//
//  SettingsViewController.swift
//  spotify-uikit
//
//  Created by Ademola Fadumo on 26/08/2023.
//

import UIKit

class SettingsViewController: UIViewController {
    
    private var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tableView
    }()
    
    private var sections = [Section]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        configureModels()
        title = "Settings"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemBackground
        
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    private func configureModels() {
        let listOfSections = [
            Section(title: "Profile", options: [Option(title: "View Your Profile", handler: handleViewProfileTapped)]),
            Section(title: "Account", options: [Option(title: "Sign Out", handler: handleSignOutTapped)]),
        ]
        
        sections.append(contentsOf: listOfSections)
    }
    
    private func handleViewProfileTapped() {
        DispatchQueue.main.async {
            let vc = ProfileViewController()
            vc.title = "Profile"
            vc.navigationItem.largeTitleDisplayMode = .never
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    private func handleSignOutTapped() {
        DispatchQueue.main.async {
            
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.frame = view.bounds
    }
}

extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - TableView
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = sections[indexPath.section].options[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = model.title
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // Call handler for cell
        let model = sections[indexPath.section].options[indexPath.row]
        model.handler()
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let model = sections[section]
        return model.title
    }
}
