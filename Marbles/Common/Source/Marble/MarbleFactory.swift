//
//  MarbleFactory.swift
//  Kulki
//
//  Created by Rafal Grodzinski on 24/04/16.
//  Copyright © 2016 UnalignedByte. All rights reserved.
//

class MarbleFactory
{
    // MARK: <<Abstract method>>
    func marbleWithColor(_ color: Int, fieldPosition: Point) -> Marble!
    {
        assert(false, "<<Abstract method>>")
        return nil
    }
}
