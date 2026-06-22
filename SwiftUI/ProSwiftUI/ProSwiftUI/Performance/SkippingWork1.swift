//
//  SkippingWork1.swift
//  ProSwiftUI
//
//  Created by yjc on 3/10/26.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

struct SkippingWork1: View {
    @State private var context = CIContext()
    @State private var name = "Paul"

    var body: some View {
        VStack {
            TextField("Enter your name", text: $name)
                .textFieldStyle(.roundedBorder)
                .padding()

            Image(uiImage: generateQRCode(from: "\(name)"))
                .resizable()
                .interpolation(.none)
                .frame(width: 200, height: 200)
        }
    }

    func generateQRCode(from string: String) -> UIImage {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)

        if let output = filter.outputImage {
            if let cgImage = context.createCGImage(output, from: output.extent) {
                return UIImage(cgImage: cgImage)
            }
        }

        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}
#Preview {
    SkippingWork1()
}
