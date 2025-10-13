//
//  PresentedSheet.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 12.10.25.
//

public enum PresentedSheet: Identifiable {
    public var id: Self { self }
    case privacy, terms
}
