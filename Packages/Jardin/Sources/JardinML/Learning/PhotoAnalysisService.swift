import CoreGraphics
import Foundation
import JardinCore

/// Point d'entrée unique pour analyser une photo d'observation :
/// empreinte (apprentissage continu), santé du feuillage, surface de premier plan.
/// Les appels Vision sont synchrones : ce service s'exécute hors du main actor.
public enum PhotoAnalysisService {
    /// Analyse sans identification (photo rattachée à une plante déjà connue).
    public static func analyze(cgImage: CGImage) async -> ObservationAnalysis {
        await Task.detached(priority: .userInitiated) {
            let health = PlantHealthAnalyzer.analyze(cgImage: cgImage)
            let featurePrint = try? FeaturePrintExtractor.extract(from: cgImage)
            return ObservationAnalysis(
                mlLabel: nil,
                mlConfidence: 0,
                healthScore: health.report.score,
                detectedIssues: health.report.issues.map { "\($0.label) — \($0.probableCauses)" },
                foregroundAreaRatio: health.foregroundAreaRatio,
                featurePrint: featurePrint
            )
        }.value
    }

    /// Analyse complète avec identification (flux « Reconnaître une plante »).
    public static func analyzeAndIdentify(cgImage: CGImage,
                                          identifier: CompositePlantIdentifier,
                                          learningExamples: [(label: String, featurePrint: Data)])
        async -> (analysis: ObservationAnalysis, identification: IdentificationOutcome) {
        let outcome = await identifier.identify(cgImage: cgImage, learningExamples: learningExamples)
        var analysis = await analyze(cgImage: cgImage)
        analysis.mlLabel = outcome.best?.name
        analysis.mlConfidence = outcome.best?.confidence ?? 0
        if analysis.featurePrint == nil { analysis.featurePrint = outcome.featurePrint }
        return (analysis, outcome)
    }
}
