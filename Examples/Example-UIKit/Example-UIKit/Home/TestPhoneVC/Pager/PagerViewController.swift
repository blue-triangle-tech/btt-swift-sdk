//
//  PagerViewController.swift
//
//  Created by JP on 15/05/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import UIKit
import BlueTriangle

class PagerViewController: UIViewController{
    
    @IBOutlet weak var scrollView : UIScrollView!
    @IBOutlet weak var pageControl : UIPageControl!
    
    private var slides:[SlideViewController] = []
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        BlueTriangle.setGroupName("CN-Pager Screen")
        self.loadSlidePages()
    }
    
    private func loadSlidePages(){
        Thread.sleep(forTimeInterval: 0.5)
        self.title = "Pager"
        
        slides = SlideViewController.getSlides()
        setupSlideScrollView(slides: slides)
        scrollView.delegate = self
        pageControl.numberOfPages = slides.count
        pageControl.currentPage = 0
    }
    
    private func setupSlideScrollView(slides : [SlideViewController]) {
        scrollView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        scrollView.contentSize = CGSize(width: view.frame.width * CGFloat(slides.count), height: view.frame.height - 150.0)
        scrollView.isPagingEnabled = true
        
        // set up pages x coordinate and height width
        for i in 0 ..< slides.count {
            slides[i].view.frame = CGRect(x: view.frame.width * CGFloat(i), y: 0, width: view.frame.width, height: view.frame.height)
            scrollView.addSubview(slides[i].view)
        }
    }
}

extension PagerViewController : UIScrollViewDelegate{
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageIndex = round(scrollView.contentOffset.x/view.frame.width)
        pageControl.currentPage = Int(pageIndex)
    }
}
