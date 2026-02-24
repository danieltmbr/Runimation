import Foundation

/// Run Processor transforms the data of a run depending
/// on its internal implementation while keeping the strucutre
/// of the data untouched.
///
/// For example it can return a run where the metrics are
/// normalised to [0, 1] or [-1, 1] ranges.
///
protocol RunProcessor {
    
    func interpolate(run: Run) -> Run
}

/// The Normalised Run interpolator maps the values
/// of each run segment between a [0, 1] or [-1, 1]
/// range depending on the metric.
///
/// Speed, time, cadence, HR are mapped between [0, 1]
/// while direction is mapped to [-1, 1].
///
/// The normalisation happens  based on the
/// spectrum of the input run.
///
struct NormalisedRun: RunProcessor {
    
    func interpolate(run: Run) -> Run {
        
    }
}

/// The Guassian Run interpolator smooths the
/// run segments to avoid fequent sudden changes.
///
/// It still allows for big changes but reduces the noise
/// in the signal that could represent a qucik stop
/// at red lights in the run or GPS animalies.
///
/// The result of this smooth curve of metrics are
/// ideal to drive animations that is not too jarring
/// especially when the animation duration is short.
///
struct GuassianRun: RunProcessor {
    
    struct Configuration {
        
        /// Sigma parameter for direction smoothing.
        ///
        let direction: CGPoint
        
        /// Sigma parameter for elevation smoothing.
        ///
        let elevation: Double
        
        /// Sigma parameter for heart rate smoothing.
        ///
        let heartRate: Double
        
        /// Sigma parameter for speed smoothing.
        ///
        let speed: Double
        
        init(
            direction: CGPoint = CGPoint(x: 25, y: 25),
            elevation: Double = 10,
            heartRate: Double = 10,
            speed: Double = 20
        ) {
            self.direction = direction
            self.elevation = elevation
            self.heartRate = heartRate
            self.speed = speed
        }
    }
    
    private let configuration: Configuration
    
    init(configuration: Configuration) {
        self.configuration = configuration
    }
    
    func interpolate(run: Run) -> Run {
        
    }
    
    private func gaussianSmooth(_ values: [Double], sigma: Double) -> [Double] {
        guard values.count > 1, sigma > 0 else { return values }
        let halfWidth = Int(ceil(sigma * 3))
        let n = values.count
        var result = [Double](repeating: 0, count: n)
        let twoSigmaSq = 2.0 * sigma * sigma
        for i in 0..<n {
            var weightSum = 0.0
            var valueSum  = 0.0
            let lo = max(0, i - halfWidth)
            let hi = min(n - 1, i + halfWidth)
            for j in lo...hi {
                let d = Double(j - i)
                let w = exp(-(d * d) / twoSigmaSq)
                weightSum += w
                valueSum  += values[j] * w
            }
            result[i] = weightSum > 0 ? valueSum / weightSum : values[i]
        }
        return result
    }
}
