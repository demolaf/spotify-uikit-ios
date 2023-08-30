//
//  ViewController.swift
//  spotify-uikit
//
//  Created by Ademola Fadumo on 26/08/2023.
//

import UIKit

class HomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        title = "Browse"
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "gear"),
            style: .done,
            target: self,
            action: #selector(didTapSettings)
        )
        
        fetchData()
    }
    
    private func fetchData() {
        APICaller.shared.getRecommendedGenres { result in
            switch result {
            case .success(let model):
                let genres = model.genres
                var seeds = Set<String>()
                while seeds.count < 5 {
                    if let random = genres.randomElement() {
                        seeds.insert(random)
                    }
                }
                
                APICaller.shared.getRecommendations(genres: seeds) { _ in
                    
                }
            case .failure(let error): break
            }
        }
    }
    
    @objc
    func didTapSettings() {
        let vc = SettingsViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}

