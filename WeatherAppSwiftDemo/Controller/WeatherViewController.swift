//
//  ViewController.swift
//  WeatherAppDemo
//
//  Created by work on 2025/2/26.
//

import UIKit
import CoreLocation
import DGCharts
import SkeletonView
class WeatherViewController: UIViewController {
    private lazy var chartView = WeatherChartView()
    private var weatherData: WeatherData?
    
    // 依赖注入
    private var networkService: NetworkServiceProtocol? = NetworkService()
    var locationService: LocationService? = LocationService()
    init(networkService: NetworkServiceProtocol = NetworkService(),
         locationService: LocationService = LocationService()) {
        self.networkService = networkService
        self.locationService = locationService
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLocation()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        setupChartView()
    }
    
    private func setupChartView() {
        chartView.translatesAutoresizingMaskIntoConstraints = false
        chartView.pinchZoomEnabled = true
        chartView.doubleTapToZoomEnabled = true
        chartView.dragEnabled = true
        chartView.delegate  = self
        view.addSubview(chartView)
        chartView.setupConstraints()
    }

    
    // MARK: - 定位与数据加载
    private func setupLocation() {
        self.locationService?.delegate = self
        self.locationService?.requestAuthorization()
        self.locationService?.startUpdatingLocation()
    }
    
    private func loadWeatherData(latitude: Double, longitude: Double) {
        showSkeleton()
        networkService?.fetchWeather(latitude: latitude, longitude: longitude) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self?.handleSuccess(data: data)
                case .failure(let error):
                    self?.handleFailure(error: error)
                }
            }
        }
    }
    
    private func handleSuccess(data: WeatherData) {
        weatherData = data
        updateChart()
        hideSkeleton()
    }
    
    private func handleFailure(error: Error) {
        showTipAlert(title: "Error", message: error.localizedDescription)
        hideSkeleton()
    }
    // 更新图表数据 (WeatherViewController 扩展)
    private func updateChart() {
        guard let hourlyData = weatherData?.hourly else { return }
        var entries = [ChartDataEntry]()
        for (index, (time, temp)) in zip(hourlyData.time, hourlyData.temperature2M).enumerated() {
            guard let date = DateFormatter.isoCustom.date(from: time) else {
                print("无法解析的时间数据点: \(time) at index \(index)")
                  continue
             }
            entries.append(ChartDataEntry(x: date.timeIntervalSince1970, y: temp))
        }
        // 创建视觉样式配置
        let dataSet = LineChartDataSet(entries: entries, label: "气温 (°C)")
        dataSet.colors = [.systemRed]
        dataSet.drawCirclesEnabled = false
        dataSet.mode = .linear  // 平滑曲线
        dataSet.lineWidth = 1.5

        // 配置坐标轴
        let xAxis = chartView.xAxis
        xAxis.valueFormatter = TimeAxisFormatter(dateFormat: "yyyy-MM-dd HH:mm:ss")
        xAxis.labelPosition = .bottom
        xAxis.avoidFirstLastClippingEnabled = true
        xAxis.granularity = 3600
        xAxis.labelRotationAngle = -60// 倾斜标签避免重叠
        xAxis.avoidFirstLastClippingEnabled = true
        xAxis.labelCount = 24
        xAxis.spaceMin = 0.5 // 左侧额外空间（数值量）
        xAxis.spaceMax = 0.5 // 右侧额外空间
        chartView.setExtraOffsets(left: -20, top: 0, right: 20, bottom: 40)
        // 应用动画渲染
        
        let leftAxis = chartView.leftAxis
        leftAxis.drawGridLinesEnabled = true
        leftAxis.gridLineDashLengths = [3, 2]
        leftAxis.gridColor = .systemGray.withAlphaComponent(0.4)
        
        UIView.transition(with: chartView, duration: 0.8, options: [.transitionCrossDissolve, .curveEaseInOut]) {
            self.chartView.data = LineChartData(dataSet: dataSet)
            self.chartView.animate(yAxisDuration: 1.2, easingOption: .easeInOutQuad)
        }
    }
    
    // 显示错误弹窗并添加重试按钮
    private func showTipAlert(title:String,message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            guard let `self` = self else {return }
            if (title == "Error"){
                self.locationService?.startUpdatingLocation()
            }
       
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    func showSkeleton() {
        let animation = SkeletonAnimationBuilder().makeSlidingAnimation(withDirection: .leftRight)
        
        chartView.isSkeletonable = true
        
        chartView.showAnimatedGradientSkeleton(animation: animation)
    }
    
    func hideSkeleton() {
        chartView.hideSkeleton(reloadDataAfter: true, transition: .crossDissolve(0.25))
    }
}

// Controller/WeatherViewController.swift
extension WeatherViewController: LocationServiceDelegate {
    func didUpdateLocation(latitude: Double, longitude: Double) {
        loadWeatherData(latitude: latitude, longitude: longitude)
        UserDefaults.standard.set([latitude, longitude], forKey: "LastKnownLocation")
    }
    
    func didFailWithError(_ error: Error) {
        // 统一转换为 LocationError 类型处理
        let locationError: LocationError
        
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                locationError = .permissionDenied
            case .locationUnknown:
                locationError = .unavailable
            default:
                locationError = .generic(clError)
            }
        } else {
            locationError = .generic(error)
        }
        
        handleLocationError(locationError)
    }
    
    // MARK: - 错误处理策略
    private func handleLocationError(_ error: LocationError) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 隐藏骨架屏
            self.hideSkeleton()
            
            // 根据错误类型展示不同提示
            switch error {
            case .permissionDenied:
                self.showPermissionAlert()
            case .unavailable:
                self.showTipAlert(title: "Error",message: "暂时无法获取位置信息，请检查网络或稍后重试")
            case .generic(let underlyingError):
                self.showTipAlert(title: "Error",message: "定位错误: \(underlyingError.localizedDescription)")
            }
        }
    }
    
    private func showPermissionAlert() {
        let alert = UIAlertController(
            title: "需要定位权限",
            message: "请到设置-隐私中开启定位权限以获取天气信息",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "去设置", style: .default) { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        })
        
        present(alert, animated: true)
    }
    
    
}

// MARK: - 自定义定位错误类型（Domain-Specific 错误处理）
enum LocationError: Error, LocalizedError {
    case permissionDenied
    case unavailable
    case generic(Error)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "定位权限被拒绝"
        case .unavailable:
            return "定位服务不可用"
        case .generic(let error):
            return "定位错误: \(error.localizedDescription)"
        }
    }
}

extension  WeatherViewController : ChartViewDelegate{
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        Logger.debug("\(entry.x)\(entry.y)")
        let  messageTip = DateFormatter.formatTimestampToDate(timestamp: entry.x,dateformat: "yyyy-MM-dd HH:mm:ss")
        showTipAlert(title: "Tip",message: "\(messageTip) - 温度:\(entry.y)")
    }
}
