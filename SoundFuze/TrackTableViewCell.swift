//
//  TrackTableViewCell.swift
//  SoundFuze
//
//  Created by Dylan Fiedler on 10/26/15.
//  Copyright © 2015 xor. All rights reserved.
//

import UIKit
import MRProgress

class TrackTableViewCell: UITableViewCell {

    @IBOutlet weak var trackName: UILabel!
    @IBOutlet weak var artist: UILabel!
    @IBOutlet weak var albumArtwork: UIImageView!
    @IBOutlet weak var progress: MRCircularProgressView!
    @IBOutlet weak var upVote: UIButton!
    @IBOutlet weak var upVoteLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        //self.upVote.alpha = 0.0
        //self.upVote.enabled = false
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
