//
//  ViewController.swift
//  microPhone
//
//  Created by Engin KUK on 23.08.2021.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        title = "add recording"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addWhistle))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Home", style: .plain, target: nil, action: nil)
    }

    @objc func addWhistle() {
        let vc = AudioRecVC()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    
    
}

