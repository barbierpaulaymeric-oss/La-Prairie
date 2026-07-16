import CoreGraphics
import Foundation
import JardinCore
import JardinML

@MainActor
final class RecognitionViewModel: ObservableObject {
    enum Phase: Equatable {
        case pickPhoto
        case analyzing
        case results
        case confirmed(plantID: UUID?)
    }

    @Published var phase: Phase = .pickPhoto
    @Published var captured: PhotoCaptureButton.Captured?
    @Published var outcome: IdentificationOutcome?
    @Published var analysis: ObservationAnalysis?
    @Published var errorMessage: String?

    private let store: GardenStore
    private let identifier: CompositePlantIdentifier

    init(store: GardenStore, identifier: CompositePlantIdentifier) {
        self.store = store
        self.identifier = identifier
    }

    func identify(_ capture: PhotoCaptureButton.Captured) {
        captured = capture
        phase = .analyzing
        errorMessage = nil
        let examples = store.learningFeaturePrints()
        Task {
            let result = await PhotoAnalysisService.analyzeAndIdentify(
                cgImage: capture.cgImage,
                identifier: identifier,
                learningExamples: examples
            )
            self.analysis = result.analysis
            self.outcome = result.identification
            self.phase = .results
        }
    }

    /// L'utilisateur valide un candidat (ou choisit manuellement une espèce si
    /// `candidate` est nil) : enregistrement de l'exemple d'apprentissage, puis
    /// création de plante ou rattachement en observation.
    func confirm(candidate: IdentificationCandidate?,
                 manualSpecies: PlantSpeciesMO?,
                 attachTo existingPlant: PlantMO?,
                 newPlantName: String?) {
        guard let captured else { return }

        let label = manualSpecies?.commonName ?? candidate?.name ?? "Plante inconnue"
        let isCorrection = manualSpecies != nil && candidate == nil
        let wasTopCandidate = candidate != nil && candidate?.normalizedName == outcome?.best?.normalizedName

        // La correction (ou le choix d'un candidat non-premier) nourrit l'apprentissage
        // avec plus de valeur qu'une simple validation.
        let source: LearningSource = isCorrection || !wasTopCandidate ? .correction : .identification

        let species = manualSpecies ?? store.findOrCreateSpecies(
            commonName: candidate?.name ?? label,
            scientificName: candidate?.scientificName
        )

        var targetPlantID: UUID?
        if let existingPlant {
            store.addObservation(to: existingPlant,
                                 note: "Identifiée « \(label) » (confiance \(Int((candidate?.confidence ?? 0) * 100)) %).",
                                 tags: [],
                                 photo: captured.stored,
                                 analysis: analysis)
            targetPlantID = existingPlant.id
        } else {
            let plant = store.createPlant(name: newPlantName?.isEmpty == false ? newPlantName! : label,
                                          species: species)
            store.addObservation(to: plant, note: nil, tags: [],
                                 photo: captured.stored, analysis: analysis)
            targetPlantID = plant.id
        }

        store.recordLearningExample(label: label,
                                    tags: [],
                                    featurePrint: analysis?.featurePrint,
                                    photo: captured.stored,
                                    source: source,
                                    plantID: targetPlantID)

        phase = .confirmed(plantID: targetPlantID)
        Task { await store.refreshNotificationSchedules() }
    }

    func reset() {
        phase = .pickPhoto
        captured = nil
        outcome = nil
        analysis = nil
        errorMessage = nil
    }
}
