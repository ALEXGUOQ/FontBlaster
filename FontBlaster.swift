//
//  FontBlaster.swift
//  FontBlaster
//
//  Created by Arthur Sabintsev on 5/5/15.
//  Copyright (c) 2015 Arthur Ariel Sabintsev. All rights reserved.
//

import Foundation
import CoreGraphics
import CoreText

// MARK: Enumerations
/**
    Limits the type of fonts that can be loaded into an application

    There are two options:
    - TrueTypeFont
    - OpenTypeFont
*/
private enum SupportedFontExtensions: String
{
    case TrueTypeFont = ".ttf"
    case OpenTypeFont = ".otf"
}

// MARK: FontBlaster Class
/**
    The FontBlaster Class.

    Only one class method can be accessed
        - blast(_:)
    Only one class variable can be accessed and modified
        - debugEnabled
*/
class FontBlaster
{
    // Typealiases to better handle of the different aspects of loading a font
    private typealias FontPath = String
    private typealias FontName = String
    private typealias FontExtension = String
    private typealias Font = (FontPath, FontName, FontExtension)
    
    /** 
        Used to toggle debug println() statements
    */
    static var debugEnabled = false
    
    /**
        Load all fonts found in a specific bundle. If no value is entered, it defaults to NSBundle.mainBundle().
    */
    class func blast(bundle: NSBundle = NSBundle.mainBundle()) {
        let path = bundle.bundlePath
        loadFontsForBundleWithPath(path)
        loadFontsFromBundlesFoundInBundle(path)
    }
}

// MARK: Helpers (Font Loading)
private extension FontBlaster
{
    /**
        Loads all fonts found in a bundle.
    
        :param: The absolute path to the bundle.
    */
    class func loadFontsForBundleWithPath(path: String) {
        var contentsError: NSError?
        let contents = NSFileManager.defaultManager().contentsOfDirectoryAtPath(path, error: &contentsError)
        if let contentsError = contentsError {
            printStatus("There was an error accessing bundle with path: \(path).")
        } else {
            let typedContents = contents as! [String]
            var fonts = fontsFromPath(path: path, contents: typedContents)
            if !fonts.isEmpty {
                for font in fonts {
                    loadFont(font)
                }
            } else {
                printStatus("No fonts were found in the bundle path: \(path).")
            }
        }
    }
    
    /**
        Loads all fonts found in a bundle that is loaded within another bundle.
        
        :param: The absolute path to the bundle.
    */
    class func loadFontsFromBundlesFoundInBundle(path: String) {
        var contentsError: NSError?
        let contents = NSFileManager.defaultManager().contentsOfDirectoryAtPath(path, error: &contentsError)
        if let contentsError = contentsError {
            printStatus("There was an error accessing bundle with path: \(path).")
        } else {
            let typedContents = contents as! [NSString]
            for item in typedContents {
                if item.containsString(".bundle") {
                    let fullPath = path.stringByAppendingPathComponent(item as! String)
                    loadFontsForBundleWithPath(fullPath)
                }
            }
        }
    }
    
    /**
        Loads a specific font.
    
        :param: The font to load.
    */
    class func loadFont(font: Font) {
        let fontPath: FontPath = font.0
        let fontName: FontPath = font.1
        let fontExtension: FontPath = font.2

        if let
            fontFileURL = NSBundle(path: fontPath)?.URLForResource(fontName, withExtension: fontExtension),
            data = NSData(contentsOfURL: fontFileURL, options: .DataReadingMappedIfSafe, error: nil)
        {
            let provider = CGDataProviderCreateWithCFData(data)
            let font = CGFontCreateWithDataProvider(provider)
            
            var fontError: Unmanaged<CFError>?
            if CTFontManagerRegisterGraphicsFont(font, &fontError) {
                let loadedFont = CGFontCopyPostScriptName(font)
                printStatus("Successfully loaded font: '\(loadedFont)'.")
            } else if let fontError = fontError?.takeRetainedValue() {
                let errorDescription = CFErrorCopyDescription(fontError)
                printStatus("Failed to load font '\(fontName)': \(errorDescription)")
            } else {
                printStatus("Failed to load font '\(fontName)'.")
            }
        }
    }
}

// MARK: Helpers (Miscellaneous)
private extension FontBlaster
{
    /**
        Parses a font into its name and extension components.
        
        :param: The absolute path to the font file.
        :returns: A tuple with the font's name and extension.
    */
    class func fontsFromPath(#path: String, contents: [NSString]) -> [Font] {
        var fonts = [Font]()
        for fontName in contents {
            if fontName.containsString(SupportedFontExtensions.TrueTypeFont.rawValue) || fontName.containsString(SupportedFontExtensions.OpenTypeFont.rawValue) {
                let parsedFont = fontFromName(fontName as! String)
                let font: Font = (path, parsedFont.0, parsedFont.1)
                fonts.append(font)
            }
        }
        
        return fonts
    }
    
    /**
        Parses a font into its name and extension components.
    
        :param: The name of the font.
        :returns: A tuple with the font's name and extension.
    */
    class func fontFromName(name: String) -> (FontName, FontExtension) {
        let components = split(name){$0 == "."}
        return (components[0], components[1])
    }
    
    /**
        Prints debug messages to the console if debugEnabled is set to true.
    
        :param: The status to print to the console.
    */
    class func printStatus(status: String) {
        if debugEnabled == true {
            println("[FontBlaster]: \(status)")
        }
    }
}
