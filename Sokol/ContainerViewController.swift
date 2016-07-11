//
//  ContainerViewController.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 16/06/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import UIKit

class ContainerViewController: UIViewController,UIScrollViewDelegate {
    let leftMenuWidth:CGFloat = 255
    @IBOutlet weak var scrollView: UIScrollView!

    override func viewDidLoad() {
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "toggleMenu", name: "toggleMenu", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "closeMenuViaNotification", name: "closeMenuViaNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "rotated", name: UIDeviceOrientationDidChangeNotification, object: nil)
    }
    override func viewWillAppear(animated: Bool) {
        dispatch_async(dispatch_get_main_queue()) { [unowned self] in
            self.closeMenu(false)
        }
    }
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func closeMenu(animated:Bool = true){
        scrollView.setContentOffset(CGPoint(x: leftMenuWidth, y: 0), animated: animated)
    }
    func openMenu(){
        scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)

    }
    func toggleMenu(){
        scrollView.contentOffset.x == 0 ? closeMenu():openMenu()
    }
    func closeMenuViaNotification(){
        closeMenu()
    }
    func rotated(){
        if UIDeviceOrientationIsLandscape(UIDevice.currentDevice().orientation) || UIDeviceOrientationIsPortrait(UIDevice.currentDevice().orientation){
            dispatch_async(dispatch_get_main_queue()) {
                self.closeMenu()
            }
        }
    }

    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        scrollView.pagingEnabled = true
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        scrollView.pagingEnabled = false
    }
    
}

