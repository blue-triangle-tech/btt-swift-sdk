//
//  TestPushViewController.swift
//
//  Created by JP on 15/05/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import UIKit
import BlueTriangle

class TestPushViewController: UIViewController {
    
    private var timer : BTTimer?
    private var memmoryTest = MemoryAllocationTest()
    private var cpuTest = CPUUsesTest()
    private var hasWarningReceived = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.resisterObserver()
        self.updateUI()
    }
    
    private func updateUI(){
        self.title = "Push"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
       /* let tracker = NetworkCaptureTracker.init(url: "https://hub.dummyapis.com/delay?seconds=3", method: "post", requestBodylength: 9130)
        tracker.submit(200, responseBodyLength: 11120, contentType: "json")*/
    }
    
    private func heavyLoopTest(){
        
        let processInfo = ProcessInfo()
        let logicalCoresCount = ProcessInfo.processInfo.processorCount
        print("Count1 :\(processInfo.activeProcessorCount)-\(logicalCoresCount)")
        
        DispatchQueue.global().async {
            let extractTaskCombination = ExtractCombination()
            let taskCombinations = extractTaskCombination.makeAllCombinations()
            print("Background Thread1: \(taskCombinations)")
        }
        
        DispatchQueue.global().async {
            let extractCombination = ExtractCombination()
            let combinations = extractCombination.makeAllCombinations()
            print("Background Thread2: \(combinations)")
        }
        
        DispatchQueue.global().async {
            let extractCombination = ExtractCombination()
            let combinations = extractCombination.makeAllCombinations()
            print("Background Thread3:  \(combinations)")
            print("Count2 :\(processInfo.activeProcessorCount)")
        }
    }
    
    private func memoryWarningTest(){
        memmoryTest.runMemoryTest()
       // cpuTest.runDoubleCoreHundradePercent()
        print("Increase 100 MB")

        //print("activeProcessorCount :\(ProcessInfo.processInfo.activeProcessorCount)")
    }
    
    @IBAction func didRunTestCase(_ sender: Any) {
        self.memoryWarningTest()
       // self.lateMomeryWarning()
    }
    
    @IBAction func didStartTimer(_ sender: Any) {
        self.startTimer()
    }
    
    @IBAction func didStopTimer(_ sender: Any) {
        self.stopTimer()
    }
    
    
    func hangMainThreadFor(seconds: Int) {
        
        print("Main thread hang")
        let semaphore = DispatchSemaphore(value: 0)
        
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(seconds)) {
            semaphore.signal()
        }
        
        semaphore.wait()
        
        print("Main thread resumed after \(seconds) seconds.")
    }
    
    private func startTimer(){
        self.timer = BlueTriangle.startTimer(page: Page(pageName:"Heavy Loop Test Case"))
        print("Start timer DONE")
    }
    
    private func stopTimer(){
        if let t = timer{
            print("Stop timer DONE")
            BlueTriangle.endTimer(t)
            timer = nil
        }
    }
    
    @objc func didReceiveWarning() {
        self.hasWarningReceived = true
    }
    
    private func resisterObserver(){
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didReceiveWarning),
                                               name: UIApplication.didReceiveMemoryWarningNotification,
                                               object: nil)
    }
    
    private func removeObserver(){
        NotificationCenter.default.removeObserver(self,
                                                          name: UIApplication.didReceiveMemoryWarningNotification,
                                                          object: nil)
    }
    
    
    // lateMemoryWarning() is a function to test the late memory warning test case. To test this, do the following:
    // Change the SDK MemoryAllocationTest runMemoryTest function allocation from 100 MB to 50 MB.
   
    private func lateMomeryWarning(){
        let startTime = Date()
        var isIncreased = false
        
        while true {
            
            let memory = self.memory()  / 1024 / 1024
            
            NSLog("\(Date()) - All Memory allocated \(memory) MB")
           
            if memory < 2060 && !isIncreased{
                if (Date().timeIntervalSince1970 - startTime.timeIntervalSince1970) < 30{
                    memmoryTest.runMemoryTest()
                }
            }else{
                isIncreased = true
                if (Date().timeIntervalSince1970 - startTime.timeIntervalSince1970) < 30{
                    memmoryTest.freeBlockMemory()
                }else{
                    break;
                }
            }
        }
    }
    
    private func memory() -> UInt64 {
        var taskInfo = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
        let result: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }

        let used: UInt64 = result == KERN_SUCCESS ? UInt64(taskInfo.phys_footprint) : 0
        return used
    }
    
    deinit {
        removeObserver()
    }
}


class ExtractCombination{
    
    var result: [String] = []

    func runInfiniteLoop(){
        
        let startTime = Date()
        
        while true {
            if (Date().timeIntervalSince1970 - startTime.timeIntervalSince1970) > 60 {
                break
            }
        }
    }
    
    func makeAllCombinations() -> [String] {
         
         result.removeAll()

         let alphabet = Array("abcdefghijklmnopqrstuvwxyz")
         let n = alphabet.count
         let desChar =  "unknwon"
         let startTime = Date()

         for length in 0..<desChar.count {
             
             for i in 0..<n {
                 
                 if (Date().timeIntervalSince1970 - startTime.timeIntervalSince1970) > 60 {
                     return []
                 }
                 
                 makeCombination(alphabet, n, length, "\(alphabet[i])")
                 
             }
         }

         return result
     }
     
     func makeCombination(_ alphabet: [Character], _ n: Int, _ length: Int, _ currentString: String) {
        
         if length == 0 {
             result.append(currentString)
             return
         }

         for i in 0..<n {
             let newString = currentString + String(alphabet[i])
             makeCombination(alphabet, n, length - 1, newString)
         }
     }
}
