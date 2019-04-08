//
//  BBMetalOverlayBlendFilter.swift
//  BBMetalImage
//
//  Created by Kaibo Lu on 4/5/19.
//  Copyright © 2019 Kaibo Lu. All rights reserved.
//

/// Applies an overlay blend of two images
public class BBMetalOverlayBlendFilter: BBMetalBaseFilter {
    public init() { super.init(kernelFunctionName: "overlayBlendKernel") }
    override func updateParameters(forComputeCommandEncoder encoder: MTLComputeCommandEncoder) {}
}
