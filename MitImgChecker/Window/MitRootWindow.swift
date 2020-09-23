//
//  MitRootWindow.swift
//  MITSourceChecker
//
//  Created by MENGCHEN on 2019/8/21.
//  Copyright © 2019 Mitchell. All rights reserved.
//

import Cocoa

class MitRootWindow: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.title = "MITSourceChecker";
    }
    @IBAction func openDocument(_ sender: AnyObject?) {
        
        let openPanel = NSOpenPanel()
        openPanel.showsHiddenFiles = false
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        
        openPanel.beginSheetModal(for: window!) { response in
            guard response.rawValue == NSApplication.ModalResponse.OK.rawValue else {
                return
            }
            self.contentViewController?.representedObject = openPanel.url
        }
    }
    

}
