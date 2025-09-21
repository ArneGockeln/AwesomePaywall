////
////  HeroView.swift
////  AwesomePaywall
////
////  Created by Arne Gockeln on 21.09.25.
////
//
//import SwiftUI
//
//// MARK: - Hero View
//extension PaywallView {
//    struct HeroView: View {
//        var body: some View {
//            VStack {
//                // Title
//                HStack {
//                    Spacer()
//                    TitleView()
//                    Spacer()
//                }
//
//                VStack(alignment: .leading) {
//                    FeatureRow(icon: "list.star", text: "Unlock All Modes")
////                    FeatureRow(icon: "person.3.fill", text: "Unlock Leaderboard")
//                    FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Unlock Progress Statistics")
//                    FeatureRow(icon: "lock.square.stack", text: "Remove anoying paywalls")
//                }
//            }
//            .padding()
//        }
//
//        // Title View
//        struct TitleView: View {
//            var body: some View {
//                ZStack {
//                    Text("PushUp Battle")
//                        .font(.system(size: 40))
//                        .bold()
//
//                    Text("Pro")
//                        .foregroundStyle(Color.white)
//                        .font(.title.bold())
//                        .padding(6)
//                        .background {
//                            RoundedRectangle(cornerRadius: 6)
//                                .foregroundStyle(Color.red)
//                        }
//                        .rotationEffect(.degrees(10))
//                        .padding(.top, 70)
//
//                }
//            }
//        }
//
//        /// Feature Row
//        struct FeatureRow: View {
//            let icon: String
//            let text: String
//
//            var body: some View {
//                HStack {
//                    RoundedRectangle(cornerRadius: 6)
//                        .overlay {
//                            Image(systemName: icon)
//                                .resizable()
//                                .aspectRatio(contentMode: .fit)
//                                .frame(width: 20, height: 20, alignment: .center)
//                                .clipped()
//                                .symbolRenderingMode(.palette)
//                                .foregroundStyle(.white)
//                                .padding(3)
//                        }
//                        .frame(width: 30, height: 30)
//
//                    Text(text)
//                }
//                .font(.system(size: 16, weight: .medium))
//            }
//        }
//    }
//}
