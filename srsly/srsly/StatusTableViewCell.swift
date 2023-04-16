//
//  StatusTableViewCell.swift
//  srsly
//
//  Created by aang on 1/28/23.
//

import UIKit

class StatusTableViewCell: UITableViewCell {
    
    @IBOutlet weak var sequencerAddressLabel: UILabel!
    @IBOutlet weak var lobbySizeLabel: UILabel!
    // i know this is spelled wrong but will fix later
    @IBOutlet weak var numberContrubtionsLabel: UILabel!
    
    static let identifier = "StatusTableViewCell"
    
    static func nib() -> UINib {
        return UINib(nibName: "StatusTableViewCell", bundle: nil)
    }
    
    public func configure(sequencerAddressLabelString: String, lobbySizeLabelString: String, numberContributionsLabel: String){
        sequencerAddressLabel.text = sequencerAddressLabelString
        lobbySizeLabel.text = lobbySizeLabelString
        numberContrubtionsLabel.text = numberContributionsLabel
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
