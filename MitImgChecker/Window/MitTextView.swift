//
//  MitTextView.swift
//  MITSourceChecker
//
//  Created by MENGCHEN on 2019/8/21.
//  Copyright © 2019 Mitchell. All rights reserved.
//

import Cocoa

class MitTextView: NSWindow {
    typealias makeSureBlock = (String)->(Void);
    typealias cancelBlock = ()->(Void);
    var keyMonitor = NSEvent.init()
    @IBOutlet weak var textField: NSTextField!
    var makeSureHandler:makeSureBlock? = nil
    var canelHandler:cancelBlock? = nil
    func sureClickCallback (closure:@escaping(String) -> Void) {
        makeSureHandler = closure
    }
    func cancelClickCallback (closure:@escaping() -> Void) {
        canelHandler = closure
    }
    @IBAction func sureClick(_ sender: Any) {
        self.close()
        makeSureHandler?(textField.stringValue)
    }
    @IBAction func cancelClick(_ sender: Any) {
        self.close()
        canelHandler?()
    }
    
}
