//
//  ContibutionTableViewCell.swift
//  srsly
//
//  Created by aang on 1/28/23.
//

import UIKit
import WebKit
import SwiftyJSON
import Combine

enum APIError: Error, LocalizedError {
    case unknown, apiError(reason: String)

    var errorDescription: String? {
        switch self {
        case .unknown:
            return "Unknown error"
        case .apiError(let reason):
            return reason
        }
    }
}


class ContibutionTableViewCell: UITableViewCell {
    
    
    
    @IBOutlet public weak var githubButton: UIButton!
    @IBOutlet public weak var siweButton: UIButton!
    @IBOutlet public weak var authType: UILabel!
    @IBOutlet public weak var sessionID: UILabel!
    @IBOutlet public weak var contributeButton: UIButton!
    @IBOutlet public weak var contributed: UILabel!
    
    public var authtext = ""
    public var githubauthurl = URL(string: "")
    public var authWithGit = false
    public var sessionIDString = ""
    public var webView = WKWebView()
    
    public weak var viewController : ViewController?
    
    
    @IBAction func githubButtonPressed(_ sender: Any) {
        print("github")
        self.authWithGit = true
        print("self.authWithGit: ", self.authWithGit)
        self.viewController?.githubAuthVC(authWithGit: self.authWithGit)
    }
    
    @IBAction func siweButtonPressed(_ sender: Any) {
        print("eth")
        self.authWithGit = false
        self.viewController?.githubAuthVC(authWithGit: self.authWithGit)
    }
    
    @IBAction func contributeButtonTapped(_ sender: Any) {
        self.contributeButton.isEnabled = false
        self.contributeButton.backgroundColor = UIColor.red
        self.viewController?.tableView.reloadData()
        self.contributed.isHidden = false
        self.contributed.text = "trying to contribute..."
        
        DispatchQueue.global().async {
            var tryAgain = true
            while(tryAgain) {
                print("trying again")
                self.viewController?.tryContributeRequest(sessionID: self.sessionIDString, requerySequencerSlot: { result in
                    tryAgain = result
                }, updatedSRS: { result in
                    DispatchQueue.main.async {
                        self.contributed?.text = "Contribution Success"
                        self.contributeButton.isEnabled = true
                        self.contributeButton.backgroundColor = UIColor.green
                    }
                })
                Thread.sleep(forTimeInterval: 30)
            }
        }
    }

    static let identifier = "ContibutionTableViewCell"
    
    static func nib() -> UINib {
        return UINib(nibName: "ContibutionTableViewCell", bundle: nil)
    }
    
    func updateAuthState(id: String){
        print("here")
        self.sessionIDString = id
        self.sessionID.text = id
        self.contributeButton.isHidden = false
        self.githubButton.isHidden = true
        self.siweButton.isHidden = true
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        githubButton.layer.cornerRadius = 5
        githubButton.layer.borderWidth = 1
        githubButton.layer.borderColor = UIColor.black.cgColor

        siweButton.layer.cornerRadius = 5
        siweButton.layer.borderWidth = 1
        siweButton.layer.borderColor = UIColor.black.cgColor
        
        contributeButton.isHidden = true
        contributed.isHidden = true

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func fetch(request: URLRequest) -> AnyPublisher<Data, APIError> {

        return URLSession.DataTaskPublisher(request: request, session: .shared)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
                    throw APIError.unknown
                }
                return data
            }
            .mapError { error in
                if let error = error as? APIError {
                    return error
                } else {
                    return APIError.apiError(reason: error.localizedDescription)
                }
            }
            .eraseToAnyPublisher()
    }
    
}
