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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
