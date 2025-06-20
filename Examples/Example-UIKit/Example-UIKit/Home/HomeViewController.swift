//
//  ViewController.swift
//
//  Created by JP on 19/05/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {
    
    private let model = HomeViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Home"
        print("Home View Load")
        
       /* DispatchQueue.main.asyncAfter(deadline: .now()) {
            Thread.sleep(forTimeInterval: 2.5)
             print("Delayed 0.5s")
         }

         DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
             Thread.sleep(forTimeInterval: 0.5)
             print("Delayed another 0.5s")
         }

         DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
             Thread.sleep(forTimeInterval: 1.0)
             print("Delayed another 1.0s")
         }*/
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("Home View Did Aprear")
    }
                                                                
}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource{
      //  MARK: Tableview Delegate & DataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return model.numberOfSection()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.numberOfRow()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = model.homeItems()[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "HomeCell")!
        cell.textLabel?.text = item
        cell.accessoryType = .disclosureIndicator
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = model.homeItems()[indexPath.row]
        
        if item == "Test Present"{
            if let vc = model.getHomeItem(item){
                self.present(vc, animated: true)
            }
        }else if item == "Test Tab"{
            if let vc = model.getHomeTabView(item){
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
        else if item == "Split View"{
            if let vc = model.getSplitView(item){
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: true)
            }
        }
        else if item == "Test Full Present"{
            if let vc = model.getHomeItem(item){
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: true)
            }
        }else{
            if let vc = model.getHomeItem(item){
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
}

