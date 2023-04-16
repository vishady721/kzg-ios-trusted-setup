//
//  VerifyTableViewCell.swift
//  srsly
//
//  Created by aang on 1/29/23.
//

import UIKit

class VerifyTableViewCell: UITableViewCell {
    
    public weak var viewController : ViewController?
    
    @IBAction func verifyButtonTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Verification", message: "Sucessfully Verified!", preferredStyle: UIAlertController.Style.alert)
        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        // show the alert
        self.viewController?.present(alert, animated: true, completion: nil)

    }
    static let identifier = "VerifyTableViewCell"
    
    static func nib() -> UINib {
        return UINib(nibName: "VerifyTableViewCell", bundle: nil)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
