//
//  ViewController.swift
//  Doorbell
//
//  Created by Jeremy Kelleher on 4/24/17.
//  Copyright © 2017 JackJeremy. All rights reserved.
//

import UIKit

class DoorbellSubscribersViewController: UIViewController {

    var phoneNumbers = [String]()
    
    @IBOutlet weak var tableView: UITableView!
    
    let JACK_SERVER_ADDRESS = "http://55359534.ngrok.io"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        // get request to access phone numbers from server
        var request = URLRequest(url: URL(string: JACK_SERVER_ADDRESS + "/numbers")!)
        request.httpMethod = "GET"
        let session = URLSession.shared
        
        session.dataTask(with: request) { (data, response, err) in
            if err != nil {
                
                // create an alert to show the error and tell the user to quit the app
                let errorAlert = UIAlertController(title: "Error Fetching from the Server", message: "Please restart the app to load phone numbers: \(String(describing: err?.localizedDescription))", preferredStyle: .alert)
                let okayAction = UIAlertAction(title: "Okay", style: .default, handler: nil)
                errorAlert.addAction(okayAction)
                
                OperationQueue.main.addOperation({
                    self.present(errorAlert, animated: true, completion: nil)
                })
                
                
            } else {
        
                guard let phoneNumbersDelimited = String(data: data!, encoding: String.Encoding.ascii) else {
                    
                    // create an alert to show the error and tell the user to quit the app
                    let errorAlert = UIAlertController(title: "Error Fetching from the Server", message: "Please restart the app to load phone numbers: \(String(describing: err?.localizedDescription))", preferredStyle: .alert)
                    let okayAction = UIAlertAction(title: "Okay", style: .default, handler: nil)
                    errorAlert.addAction(okayAction)
                    
                    OperationQueue.main.addOperation({
                        self.present(errorAlert, animated: true, completion: nil)
                    })
                    
                    return
                    
                }
                
                // parse the phone numbers returned from the server
                let seperatedPhoneNumbersAndSpaces: [String] = phoneNumbersDelimited.components(separatedBy: " ")
                
                // remove spaces
                var seperatedPhoneNumbers = [String]()
                
                for entry in seperatedPhoneNumbersAndSpaces {
                    if entry.isEmpty || entry == "" || entry == " " {
                        continue
                    } else {
                        seperatedPhoneNumbers.append(entry)
                    }
                }
                
                self.phoneNumbers = seperatedPhoneNumbers
                OperationQueue.main.addOperation({
                    self.tableView.reloadData()
                })
                
            }
            
        }.resume()
        
    }

    @IBAction func addButtonPressed(_ sender: Any) {
        
        let addPhoneNumberAlert = UIAlertController(title: "Add Doorbell Subscriber", message: "Enter the phone number to be notified via text when the doorbell rings \n (only 10 numeric characters starting with a 1!)", preferredStyle: .alert)
        addPhoneNumberAlert.addTextField { (textField) in
            textField.keyboardType = .numberPad
        }
        
        let addAction = UIAlertAction(title: "Add", style: .default) { (_) in
            
            // get phone number from textfield
            guard let text = addPhoneNumberAlert.textFields?.first?.text else {
                return
            }
            
            // make sure the phone number text matches the phone number regex
            let phoneNumberRegex = try! NSRegularExpression(pattern: "1[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]", options: NSRegularExpression.Options.allowCommentsAndWhitespace)
            let matches: [NSTextCheckingResult] = phoneNumberRegex.matches(in: text, options: NSRegularExpression.MatchingOptions.anchored, range: NSRange(location: 0, length: text.characters.count))
            if matches.isEmpty {
                
                let errorAlert = UIAlertController(title: "Incorrect Format", message: "Your phone number must start with a 1 followed by 10 digits", preferredStyle: .alert)
                let okayAction = UIAlertAction(title: "Okay", style: .default, handler: nil)
                errorAlert.addAction(okayAction)
                
                OperationQueue.main.addOperation({
                    self.present(errorAlert, animated: true, completion: nil)
                })
                
                return
                
            }
            
            // grab the first match
            let phoneNumberMatchResult = matches.first!
            let phoneNumber = (text as NSString).substring(with: phoneNumberMatchResult.range)
            
            // check for duplicates 
            for existingNumber in self.phoneNumbers {
                if phoneNumber == existingNumber { // found duplicate
                    
                    let errorAlert = UIAlertController(title: "Duplicate Phone Number", message: "\(phoneNumber) already subscribes to doorbell notifications", preferredStyle: .alert)
                    let okayAction = UIAlertAction(title: "Okay", style: .default, handler: nil)
                    errorAlert.addAction(okayAction)
                    
                    OperationQueue.main.addOperation({
                        self.present(errorAlert, animated: true, completion: nil)
                    })
                    
                    return
                }
            }
            
            // save the phone number to the server
            var request = URLRequest(url: URL(string: self.JACK_SERVER_ADDRESS + "/add/" + phoneNumber)!)
            request.httpMethod = "POST"
            let session = URLSession.shared
            
            session.dataTask(with: request) {data, response, err in
                
                if err != nil {
                    
                    // create an alert to show the error and tell the user to quit the app
                    let errorAlert = UIAlertController(title: "Error Sending Phone Number to the Server", message: "\(String(describing: err?.localizedDescription))", preferredStyle: .alert)
                    let okayAction = UIAlertAction(title: "Okay", style: .default, handler: nil)
                    errorAlert.addAction(okayAction)
                    
                    OperationQueue.main.addOperation({
                        self.present(errorAlert, animated: true, completion: nil)
                    })
                    
                } else { // if there is no problem save the phone number to the device
                    
                    // save the phone number to the device
                    self.phoneNumbers.append(phoneNumber)
                    OperationQueue.main.addOperation({
                        self.tableView.reloadData()
                    })
                    
                }
                
            }.resume()
            
//            // TODO - Remove after network code works
//            self.phoneNumbers.append(phoneNumber)
//            OperationQueue.main.addOperation({
//                self.tableView.reloadData()
//            })
            
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        addPhoneNumberAlert.addAction(addAction)
        addPhoneNumberAlert.addAction(cancelAction)
        
        self.present(addPhoneNumberAlert, animated: true, completion: nil)
    }

}

extension DoorbellSubscribersViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return phoneNumbers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "DoorbellRingersTableViewCell", for: indexPath)
        cell.textLabel?.text = phoneNumbers[indexPath.row]
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // call the phone number
        tableView.deselectRow(at: indexPath, animated: true)
        if let url = URL(string: "tel://\(self.phoneNumbers[indexPath.row])"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            // delete phone number from server
            var request = URLRequest(url: URL(string: self.JACK_SERVER_ADDRESS + "/remove/" + phoneNumbers[indexPath.row])!)
            request.httpMethod = "POST"
            let session = URLSession.shared
            
            session.dataTask(with: request) {data, response, err in
                
                if err != nil {
                    
                    // create an alert to show the error and tell the user to quit the app
                    let errorAlert = UIAlertController(title: "Error Removing Phone Number from the Server", message: "\(String(describing: err?.localizedDescription))", preferredStyle: .alert)
                    let okayAction = UIAlertAction(title: "Okay", style: .default, handler: nil)
                    errorAlert.addAction(okayAction)
                    
                    OperationQueue.main.addOperation({
                        self.present(errorAlert, animated: true, completion: nil)
                    })
                    
                } else { // if there is no problem removing the phone number, then delete it from the device
                    
                    // delete number from phone
                    self.phoneNumbers.remove(at: indexPath.row)
                    OperationQueue.main.addOperation({
                        self.tableView.reloadData()
                    })
                    
                    
                }
                
                }.resume()
            
//            // TODO - remove once network code works
//            self.phoneNumbers.remove(at: indexPath.row)
//            OperationQueue.main.addOperation({
//                self.tableView.reloadData()
//            })
            
        }
    }
    
}



