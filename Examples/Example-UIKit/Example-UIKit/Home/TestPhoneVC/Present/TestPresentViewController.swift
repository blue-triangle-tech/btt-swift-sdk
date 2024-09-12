//
//  TestPresentViewController.swift
//
//  Created by JP on 15/05/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import UIKit

class TestPresentViewController: UIViewController {

    @IBOutlet weak var lblTitle : UILabel!
    @IBOutlet weak var lblId : UILabel!
    @IBOutlet weak var lblDesc : UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateUI()
    }
    
    private func updateUI(){
        
        self.title = "Present Default"
        
        lblTitle.text = "\(type(of: self))"
        lblId.text = "SleepTime : 5 sec" + "\n"
        lblDesc.text = "This screen is an UIViewController sub class. Presented on UIViewController using func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) with  default modalPresentationStyle."
    }
   
    @IBAction func didSelectForcedOptionalCrash(_ sender : Any){
        NSLog("\(#fileID) \(#line)")
        var tmp : String?
        NSLog("%@", tmp!)
    }
    
    @IBAction func didSelectIndexOutOfBoundCrash(_ sender : Any){
        NSLog("\(#fileID) \(#line)")
        Task.detached {
            let list = [1, 2]
            NSLog("Values which not found", list[10])
        }
    }
    
    @IBAction func didSelectFatalError(_ sender : Any){
        NSLog("\(#fileID) \(#line)")
        fatalError("This is a fatal error")
    }
    
    @IBAction func didSelectUnsafeMemoryAccess(_ sender : Any){
        NSLog("\(#fileID) \(#line)")
        let pointer = UnsafeMutablePointer<Int>.allocate(capacity: 1)
        // Deallocate the memory
        pointer.deallocate()
        // Access the deallocated memory
        pointer.pointee = 42
    }
    
    @IBAction func didSelectDivideByZero(_ sender : Any){
        NSLog("\(#fileID) \(#line)")
        var op1 = "\(1)".count
        var op2 = op1 - 1
        var result = op1 / op2
        NSLog("Result : \(result)")
    }
    
    @IBAction func didSelectSegmentationFault(_ sender : Any){
        NSLog("\(#fileID) \(#line)")
        var pointer: UnsafeMutablePointer<Int>? = nil
        pointer!.pointee = 42  // This should cause a SIGSEGV
    }
}
