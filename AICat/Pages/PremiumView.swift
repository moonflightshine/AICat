//
//  PremiumView.swift
//  AICat
//
//  Created by Lei Pan on 2023/4/13.
//

/// View Structure generated by GPT-4
import SwiftUI
import ApphudSDK
import ComposableArchitecture

struct PremuimPageReducer: ReducerProtocol {
    struct State: Equatable {
        var product: ApphudProduct?
        var toast: Toast?
        var isPurchasing: Bool = false

        var price: String {
            product?.skProduct?.locatedPrice ?? "_._"
        }

        var isPremium: Bool {
            UserDefaults.openApiKey != nil || Apphud.hasPremiumAccess()
        }
    }

    enum Action {
        case onAppear
        case updateProduct(ApphudProduct?)
        case setToast(Toast?)
        case setIsPurchasing(Bool)
        case subscribeNow
        case restore
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .onAppear:
            return .task {
                let product = await fetchPayWall()
                return .updateProduct(product)
            }
        case .updateProduct(let product):
            state.product = product
            return .none
        case .setIsPurchasing(let value):
            state.isPurchasing = value
            return .none
        case .setToast(let toast):
            state.toast = toast
            return .none
        case .subscribeNow:
            guard !state.isPurchasing, !state.isPremium, let product = state.product else { return .none }
            return .run { send in
                await send(.setIsPurchasing(true))
                let result = await Apphud.purchase(product)
                if result.success {
                    let toast = Toast(type: .success, message: "You get AICat Premium Now!", duration: 2)
                    await send(.setToast(toast))
                }
                if let error = result.error as? NSError {
                    let toast = Toast(type: .error, message: "Purchase failed, \(error.localizedDescription))", duration: 4)
                    await send(.setToast(toast))
                } else if result.error != nil {
                    let toast = Toast(type: .error, message: "Purchase failed!", duration: 2)
                    await send(.setToast(toast))
                }
                await send(.setIsPurchasing(false))
            }
        case .restore:
            guard !state.isPurchasing, state.product != nil else { return .none }
            return .run { send in
                await send(.setIsPurchasing(true))
                let _ = await Apphud.restorePurchases()
                await send(.setIsPurchasing(false))
                if Apphud.hasPremiumAccess() {
                    let toast = Toast(type: .success, message: "You get AICat Premium Now!", duration: 2)
                    await send(.setToast(toast))
                } else {
                    let toast = Toast(type: .error, message: "You are not premium user!", duration: 2)
                    await send(.setToast(toast))
                }
            }
        }
    }

    func fetchPayWall() async -> ApphudProduct? {
        if let payWall = await Apphud.paywalls().first, let product = payWall.products.first {
            return product
        }
        return nil
    }
}

struct PremiumPage: View {

    let store: StoreOf<PremuimPageReducer> = Store(initialState: .init(), reducer: PremuimPageReducer())
    let onClose: () -> Void

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        onClose()
                    }) {
                        Image(systemName: "xmark")
                            .resizable()
                            .frame(width: 16, height: 16)
                            .padding(16)
                    }
                    .tint(.primaryColor)
                    .buttonStyle(.borderless)
                }
                Spacer()
                Text("AICat Premium")
                    .font(.manrope(size: 36, weight: .bold))
                    .fontWeight(.bold)
                    .padding(.top, 20)

                VStack(alignment: .leading, spacing: 20) {
                    FeatureView(title: "Answers from GPT Model", description: "Get accurate and relevant answers directly from the GPT Model.")
                    FeatureView(title: "No limits for Dialogues", description: "Engage in unlimited dialogues without any restrictions.")
                    FeatureView(title: "Higher word limit", description: "Enjoy extended conversations with a higher word limit per message.")
                    FeatureView(title: "Get new features first", description: "Be the first to access and try out new and upcoming features.")
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 40)
                Spacer()
                Button(action: {
                    viewStore.send(.restore)
                }) {
                    Text("Restore Purchases")
                        .underline()
                        .foregroundColor(.blue)
                }
                .buttonStyle(.borderless)
                Button(action: {
                    viewStore.send(.subscribeNow)
                }) {
                    ZStack {
                        Text(viewStore.isPremium ? "Already Premium" : "Subscribe for \(viewStore.price)/month")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 40)
                            .opacity((viewStore.product == nil || viewStore.isPurchasing) ? 0 : 1)
                            .background(Color.blue)
                            .cornerRadius(8)
                        if viewStore.product == nil || viewStore.isPurchasing {
                            LoadingIndocator(themeColor: .white)
                                .frame(width: 20, height: 20)
                                .environment(\.colorScheme, .dark)
                        }
                    }

                }
                .buttonStyle(.borderless)
                Text("Auto renewal monthly, cancel at anytime")
                    .foregroundColor(.gray.opacity(0.6))
                    .font(.manrope(size: 12, weight: .regular))
                    .padding(.bottom, 10)

                HStack {
                    Link(destination: URL(string: "https://epochpro.app/aicat_privacy")!) {
                        Text("Privacy Policy")
                            .underline()
                            .foregroundColor(.blue)
                    }

                    Text("|")
                        .padding(.horizontal, 4)

                    Link(destination: URL(string: "https://epochpro.app/aicat_terms_of_use")!) {
                        Text("Terms of Use")
                            .underline()
                            .foregroundColor(.blue)
                    }
                }
                .font(.footnote)
                .padding(.bottom, 20)
                Spacer()
            }
            .font(.manrope(size: 16, weight: .medium))
            .onAppear {
                viewStore.send(.onAppear)
            }
            .background(Color.background.ignoresSafeArea())
            .toast(viewStore.binding(get: \.toast, send: PremuimPageReducer.Action.setToast))
        }
    }
}

struct FeatureView: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "crown.fill")

                Text(LocalizedStringKey(title))
                    .font(.manrope(size: 16, weight: .bold))
            }

            Text(LocalizedStringKey(description))
                .font(.manrope(size: 14, weight: .medium))
                .foregroundColor(.gray)
                .padding(.leading, 32)
        }
    }
}

struct PremiumPage_Previews: PreviewProvider {
    static var previews: some View {
        PremiumPage(onClose: {})
            .background(.background)
            .environment(\.colorScheme, .dark)
    }
}

