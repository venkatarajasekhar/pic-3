//
//  RecordButton.swift
//  Pic
//
//  Created by Kashish Hora on 12/27/14.
//  Copyright (c) 2014 Kashish Hora. All rights reserved.
//

import UIKit

protocol RecordButtonDelegate {
    func toggleRecording()
    var currentlyRecording: Bool { get }
}

class RecordButton: UIButton {

    var delegate: RecordButtonDelegate?
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.addTarget(self, action: Selector("toggleRecording"), forControlEvents: .TouchUpInside)
    }
    
    func toggleRecording() {
        // Add UI functionality here
        
        self.delegate?.toggleRecording()
    }

    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
