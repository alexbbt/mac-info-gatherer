//
//  AppDelegate.swift
//  Info Gatherer
//
//  Created by Alexander Bell-Towne on 8/20/15.
//  Copyright (c) 2015 Alexander Bell-Towne. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    // App Text Config
    struct Config {

        static let name = "YOUR NAME"
        static let email = "your@email.com"
        static let phone = "(555) 555-5555"

        // URL where data should be sent
        static let url = "https://submission.url.com/phpfile.php"

        // Description for the top of the app
        static let description = "Experiencing technical difficulty? Please fill out this form to notify " + Config.name + ""

        // All input fields
        struct fields {
            struct name {
                static let label = "name:"
                static let placeholder = "John Appleseed"
            }
            struct email {
                static let label = "email:"
                static let placeholder = "user@example.com"
            }
            struct comments {
                static let label = "Feedback or Description of Problem:"
            }
        }

        // Send button and reactions
        struct send {
            static let submitButton = "Submit"

            // Messages to display on either of these outcomes from sending the data.
            static let success = "Information successfully sent to " + Config.name + ". Thank you."
            static let error = "ERROR! Information NOT sent to " + Config.name + ". Please contact us at " + Config.email + " or " + Config.phone + ""

            // Button after info is sent which closes the app.
            static let finalButton = "Okay"
        }

    }

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // initialize application
        setup()

        // Sets Quit on Close button (so the app doesn't stay open in the task bar when they close it)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AppDelegate.quit), name: NSWindowWillCloseNotification, object: nil)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
        // Nothing needed
    }

    // Data struct to store Information accross functions
    struct dataToSend {
        static var userName: String = "\\\\" + NSUserName() // the \\\\ is so that it looks like a windows username for the PHP file, i.e. "\\user.name"
        static var name: String = String()
        static var machineName: String = String()
        static var timeStamp: String = String()
        static var email: String = String()
        static var comments: String = String()
        static var ipAddress: String = String()
        static var processes: NSDictionary = NSDictionary()
        static var error: Bool = false // error sending so message will be different
    }

    // links to UI elements
    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var name: NSTextField! // Name input field
    @IBOutlet weak var email: NSTextField! // Email input field
    @IBOutlet var comments: NSTextView! // Feedback or Description of Problem input box (allows multible lines)

    // links to UI View elements
    @IBOutlet weak var displayMessage: NSTextField!
    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var emailLabel: NSTextField!
    @IBOutlet weak var commentsLabel: NSTextField!
    @IBOutlet weak var submitButton: NSButton!

    // Set all text
    func setup() {
        displayMessage.stringValue = Config.description
        nameLabel.stringValue = Config.fields.name.label
        emailLabel.stringValue = Config.fields.email.label
        commentsLabel.stringValue = Config.fields.comments.label

        name.placeholderString = Config.fields.name.placeholder
        email.placeholderString = Config.fields.email.placeholder

        submitButton.title = Config.send.submitButton
    }

    // Enables close button in file menu
    @IBAction func quitButton(sender: AnyObject) {
        quit()
    }

    // Quits app
    func quit() {
        NSApplication.sharedApplication().terminate(self)
    }

    // When submit button clicked
    @IBAction func submit(sender: NSButton) {
        dataToSend.machineName = getHost()
        dataToSend.timeStamp = getTime()
        dataToSend.processes = getPIDs() // Gets Data Array of running processes
        getIPs()
        dataToSend.name = name.stringValue
        dataToSend.email = email.stringValue
        dataToSend.comments = ((comments.textStorage as NSTextStorage!).string).condenseWhitespace() // Gets comments and removes extra white space and new lines

        send_Data(make_json()) // Sends JSON String

        // Alert and close
        let sent: NSAlert = NSAlert()
        if !dataToSend.error {
            sent.messageText = Config.send.success
            sent.alertStyle = NSAlertStyle.InformationalAlertStyle
        } else {
            sent.messageText = Config.send.error
            sent.alertStyle = NSAlertStyle.WarningAlertStyle
        }
        sent.addButtonWithTitle(Config.send.finalButton)
        let res = sent.runModal()

        // If "Okay" clicked
        if res == NSAlertFirstButtonReturn {
            quit()
        }
    }

    // Return computer name
    func getHost() -> String{
        let host:NSHost = NSHost()
        return host.localizedName!
    }

    // Return current time stamp
    func getTime() -> String{
        let date = NSDate()
        let formatter = NSDateFormatter()
        formatter.dateStyle = .ShortStyle
        formatter.timeStyle = .ShortStyle
        return formatter.stringFromDate(date)
    }

    // Turns data in to JSON String (Faster than using NSData object)
    func make_json() -> String{
        let dict: NSDictionary = [
            "name":dataToSend.name,
            "email": dataToSend.email,
            "comments": dataToSend.comments,
            "username": dataToSend.userName,
            "ipAddress": dataToSend.ipAddress,
            "machineName": dataToSend.machineName,
            "timeStamp": dataToSend.timeStamp,
            "processes": dataToSend.processes
        ]
        var jsonString: NSString
        do {
            let jsonData: NSData = try NSJSONSerialization.dataWithJSONObject(dict, options: NSJSONWritingOptions())
            jsonString = NSString(data: jsonData, encoding: NSASCIIStringEncoding)!
        } catch {
            jsonString = ""
        }
        return jsonString as String
    }

    // Send data to php file
    func send_Data(json: String) {
        let request = NSMutableURLRequest(URL: NSURL(string: Config.url)!)
        request.HTTPMethod = "POST"
        let postString = "json=" + (json as String)
        request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding)
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            data, response, error in

            if error != nil {
                dataToSend.error = true // Sets Error for final Message
                return
            }

            _ = NSString(data: data!, encoding: NSUTF8StringEncoding)
        }
        task.resume() // Send

    }

    // Gets IP addresses and Puts them in storage
    func getIPs() {
        let ips: [String] = getIFAddresses()
        var index = 1
        for ip in ips {
            if index != 1 {
                dataToSend.ipAddress += " - " // Spacer as PHP form expects only one IP
            }
            dataToSend.ipAddress += ip
            index = index + 1
        }
    }

    // Returns array of IP addresses
    func getIFAddresses() -> [String] {
        var addresses = [String]()

        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs> = nil
        if getifaddrs(&ifaddr) == 0 {

            // while there is a next interface interface ...
            var ptr = ifaddr
            while ptr != nil {
                let flags = Int32(ptr.memory.ifa_flags)
                var addr = ptr.memory.ifa_addr.memory

                // Check for running IPv4, IPv6 interfaces. Skip the loopback interface.
                if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
                    if addr.sa_family == UInt8(AF_INET) || addr.sa_family == UInt8(AF_INET6) {

                        // Convert interface address to a human readable string:
                        var hostname = [CChar](count: Int(NI_MAXHOST), repeatedValue: 0)
                        if (getnameinfo(&addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count),
                            nil, socklen_t(0), NI_NUMERICHOST) == 0) {
                            if let address = String.fromCString(hostname) {
                                addresses.append(address)
                            }
                        }
                    }
                }

                // next interface
                ptr = ptr.memory.ifa_next
            }

            freeifaddrs(ifaddr)
        }

        return addresses
    }

    // Returns array of PID's and their Names
    func getPIDs() -> NSDictionary{
        let task = NSTask() // Runs shell command and grabs output
        task.launchPath = "/usr/bin/pgrep" // Command
        task.arguments = ["-l", "^"] // Options, -l is include process name, ^ is all processes

        let pipe = NSPipe()
        task.standardOutput = pipe
        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output: NSString = NSString(data: data, encoding: NSUTF8StringEncoding)!
        let array: NSArray = output.componentsSeparatedByString("\n") // Splits output string by line
        let dict: NSMutableDictionary = NSMutableDictionary()
        for process in array {
            let smallArray: NSArray = process.componentsSeparatedByString(" ") // Splits line by space
            var pid: String = ""
            var name: String = ""
            for part in smallArray {
                if Int((part as! String)) != nil {
                    pid = part as! String
                } else {
                    if name != "" {
                        name += " "
                    }
                    name += part as! String // puts back together the name as one string
                }
            }
            if( pid != "" && name != "") {
                dict[pid] = name
            }
        }
        return dict
    }
}

//Removes extra white space from string
extension String {
    func condenseWhitespace() -> String {
        let components = self.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        return components.filter { !$0.isEmpty }.joinWithSeparator(" ")
    }
}