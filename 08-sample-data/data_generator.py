"""
Manufacturing Sensor Data Generator
Generates realistic sensor data for testing the data pipeline
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import json
import random
import os
from typing import Dict, List

class ManufacturingDataGenerator:
    """Generate realistic manufacturing sensor data for testing"""
    
    def __init__(self, start_date: str = "2024-01-01", num_days: int = 30):
        self.start_date = pd.to_datetime(start_date)
        self.num_days = num_days
        self.sensors = self._create_sensor_config()
        self.equipment = self._create_equipment_config()
        
    def _create_sensor_config(self) -> List[Dict]:
        """Configure sensor parameters for realistic data generation"""
        return [
            {
                "sensor_id": "TEMP_001",
                "equipment_id": "EQ_FURNACE_01",
                "type": "temperature",
                "location": "Production Line A",
                "normal_range": (20, 25),
                "alert_threshold": (15, 35),
                "error_rate": 0.02
            },
            {
                "sensor_id": "TEMP_002", 
                "equipment_id": "EQ_FURNACE_02",
                "type": "temperature",
                "location": "Production Line B", 
                "normal_range": (22, 28),
                "alert_threshold": (18, 40),
                "error_rate": 0.015
            },
            {
                "sensor_id": "HUM_001",
                "equipment_id": "EQ_CHAMBER_01",
                "type": "humidity",
                "location": "Quality Control",
                "normal_range": (45, 55),
                "alert_threshold": (30, 70),
                "error_rate": 0.01
            },
            {
                "sensor_id": "PRESS_001",
                "equipment_id": "EQ_COMPRESSOR_01", 
                "type": "pressure",
                "location": "Pneumatic System",
                "normal_range": (100, 120),
                "alert_threshold": (80, 150),
                "error_rate": 0.025
            },
            {
                "sensor_id": "VIB_001",
                "equipment_id": "EQ_MOTOR_01",
                "type": "vibration",
                "location": "Motor Assembly",
                "normal_range": (0.1, 0.3),
                "alert_threshold": (0.05, 0.8),
                "error_rate": 0.03
            }
        ]
    
    def _create_equipment_config(self) -> List[Dict]:
        """Configure equipment for log generation"""
        return [
            {
                "equipment_id": "EQ_FURNACE_01",
                "name": "Industrial Furnace Unit 1",
                "type": "Heating Equipment",
                "location": "Production Line A",
                "status": "operational"
            },
            {
                "equipment_id": "EQ_FURNACE_02", 
                "name": "Industrial Furnace Unit 2",
                "type": "Heating Equipment",
                "location": "Production Line B",
                "status": "operational"
            },
            {
                "equipment_id": "EQ_CHAMBER_01",
                "name": "Environmental Chamber",
                "type": "Climate Control",
                "location": "Quality Control",
                "status": "operational"
            },
            {
                "equipment_id": "EQ_COMPRESSOR_01",
                "name": "Air Compressor System",
                "type": "Pneumatic Equipment", 
                "location": "Pneumatic System",
                "status": "operational"
            },
            {
                "equipment_id": "EQ_MOTOR_01",
                "name": "Primary Drive Motor",
                "type": "Motor Assembly",
                "location": "Motor Assembly", 
                "status": "operational"
            }
        ]
    
    def generate_sensor_data(self, records_per_day: int = 1440) -> pd.DataFrame:
        """
        Generate sensor readings data
        
        Args:
            records_per_day: Number of sensor readings per day (default: every minute)
            
        Returns:
            DataFrame with sensor readings
        """
        data = []
        
        for day in range(self.num_days):
            current_date = self.start_date + timedelta(days=day)
            
            for minute in range(0, 1440, 1440 // records_per_day):
                timestamp = current_date + timedelta(minutes=minute)
                
                for sensor in self.sensors:
                    # Simulate sensor reading with some realistic patterns
                    base_value = self._generate_realistic_value(sensor, timestamp)
                    
                    # Add some noise
                    noise = np.random.normal(0, 0.1)
                    value = base_value + noise
                    
                    # Simulate occasional anomalies
                    is_anomaly = random.random() < sensor["error_rate"]
                    if is_anomaly:
                        # Generate anomalous reading
                        anomaly_factor = random.choice([-2, -1.5, 1.5, 2])
                        value = base_value * anomaly_factor
                    
                    # Calculate quality score
                    quality_score = self._calculate_quality_score(sensor, value)
                    
                    record = {
                        "sensor_id": sensor["sensor_id"],
                        "equipment_id": sensor["equipment_id"],
                        "timestamp": timestamp.strftime("%Y-%m-%d %H:%M:%S"),
                        "value": round(value, 3),
                        "sensor_type": sensor["type"],
                        "location": sensor["location"],
                        "status": "error" if is_anomaly else "normal",
                        "quality_score": round(quality_score, 3),
                        "is_anomaly": is_anomaly
                    }
                    
                    # Add sensor-specific fields
                    if sensor["type"] == "temperature":
                        record["temperature"] = record["value"]
                        record["unit"] = "celsius"
                    elif sensor["type"] == "humidity":
                        record["humidity"] = record["value"] 
                        record["unit"] = "percent"
                    elif sensor["type"] == "pressure":
                        record["pressure"] = record["value"]
                        record["unit"] = "psi"
                    elif sensor["type"] == "vibration":
                        record["vibration_magnitude"] = record["value"]
                        record["vibration_x"] = round(value + np.random.normal(0, 0.02), 4)
                        record["vibration_y"] = round(value + np.random.normal(0, 0.02), 4) 
                        record["vibration_z"] = round(value + np.random.normal(0, 0.02), 4)
                        record["unit"] = "g"
                    
                    data.append(record)
        
        return pd.DataFrame(data)
    
    def _generate_realistic_value(self, sensor: Dict, timestamp: datetime) -> float:
        """Generate realistic sensor value based on time patterns"""
        # Base value from normal range
        min_val, max_val = sensor["normal_range"]
        base_value = random.uniform(min_val, max_val)
        
        # Add daily patterns (some equipment runs hotter during day shift)
        hour = timestamp.hour
        if sensor["type"] == "temperature":
            # Higher temperature during day shift (6 AM - 6 PM)
            if 6 <= hour <= 18:
                base_value += random.uniform(1, 3)
        
        # Add weekly patterns (lower activity on weekends)
        if timestamp.weekday() >= 5:  # Weekend
            base_value *= 0.95
        
        # Add seasonal trends (temperature sensors affected by ambient)
        if sensor["type"] == "temperature":
            day_of_year = timestamp.timetuple().tm_yday
            seasonal_adjustment = 2 * np.sin(2 * np.pi * day_of_year / 365)
            base_value += seasonal_adjustment
            
        return base_value
    
    def _calculate_quality_score(self, sensor: Dict, value: float) -> float:
        """Calculate data quality score based on sensor reading"""
        min_normal, max_normal = sensor["normal_range"]
        min_alert, max_alert = sensor["alert_threshold"]
        
        if min_normal <= value <= max_normal:
            return random.uniform(0.95, 1.0)  # High quality for normal readings
        elif min_alert <= value <= max_alert:
            return random.uniform(0.7, 0.9)   # Medium quality for alert range
        else:
            return random.uniform(0.1, 0.6)   # Low quality for out-of-range
    
    def generate_equipment_logs(self, logs_per_day: int = 100) -> List[Dict]:
        """
        Generate equipment log entries
        
        Args:
            logs_per_day: Number of log entries per day per equipment
            
        Returns:
            List of log entries as dictionaries
        """
        logs = []
        log_levels = ["INFO", "WARNING", "ERROR", "DEBUG"]
        
        for day in range(self.num_days):
            current_date = self.start_date + timedelta(days=day)
            
            for equipment in self.equipment:
                for _ in range(logs_per_day):
                    # Random time during the day
                    random_seconds = random.randint(0, 86399)
                    timestamp = current_date + timedelta(seconds=random_seconds)
                    
                    # Generate log based on equipment type and random events
                    log_entry = self._generate_log_entry(equipment, timestamp)
                    logs.append(log_entry)
        
        return logs
    
    def _generate_log_entry(self, equipment: Dict, timestamp: datetime) -> Dict:
        """Generate a single log entry for equipment"""
        log_templates = {
            "INFO": [
                "Equipment startup completed successfully",
                "Maintenance cycle completed",
                "Performance metrics within normal range", 
                "System health check passed",
                "Configuration updated successfully"
            ],
            "WARNING": [
                "Temperature approaching upper threshold",
                "Vibration levels elevated but within limits",
                "Maintenance due within 24 hours",
                "Performance efficiency below optimal",
                "Sensor calibration recommended"
            ],
            "ERROR": [
                "Temperature exceeded safety threshold",
                "Unexpected shutdown detected",
                "Sensor malfunction detected",
                "Communication timeout with control system",
                "Safety interlock triggered"
            ],
            "DEBUG": [
                "Sensor reading validation completed",
                "Control loop iteration completed",
                "Memory usage check completed",
                "Network heartbeat successful",
                "Configuration parameter updated"
            ]
        }
        
        # Weight log levels (more INFO, less ERROR)
        level_weights = {"INFO": 0.6, "WARNING": 0.25, "ERROR": 0.05, "DEBUG": 0.1}
        log_level = np.random.choice(list(level_weights.keys()), p=list(level_weights.values()))
        
        message = random.choice(log_templates[log_level])
        
        log_entry = {
            "equipment_id": equipment["equipment_id"],
            "equipment_name": equipment["name"],
            "timestamp": timestamp.strftime("%Y-%m-%d %H:%M:%S"),
            "log_level": log_level,
            "message": message,
            "location": equipment["location"],
            "equipment_type": equipment["type"],
            "status": equipment["status"]
        }
        
        # Add additional fields for certain log types
        if log_level == "ERROR":
            log_entry["error_code"] = f"ERR_{random.randint(1000, 9999)}"
            log_entry["severity"] = random.choice(["LOW", "MEDIUM", "HIGH", "CRITICAL"])
        
        if log_level == "WARNING":
            log_entry["warning_code"] = f"WARN_{random.randint(100, 999)}"
        
        # Add some operational parameters
        log_entry["parameters"] = {
            "cpu_usage": round(random.uniform(10, 90), 2),
            "memory_usage": round(random.uniform(20, 80), 2),
            "network_latency": round(random.uniform(1, 50), 2)
        }
        
        return log_entry
    
    def generate_quality_metrics(self) -> pd.DataFrame:
        """Generate quality control metrics"""
        metrics = []
        
        for day in range(self.num_days):
            current_date = self.start_date + timedelta(days=day)
            
            # Daily quality metrics per equipment
            for equipment in self.equipment:
                metric = {
                    "equipment_id": equipment["equipment_id"],
                    "date": current_date.strftime("%Y-%m-%d"),
                    "location": equipment["location"],
                    "uptime_hours": round(random.uniform(20, 24), 2),
                    "downtime_hours": round(random.uniform(0, 4), 2),
                    "efficiency_percentage": round(random.uniform(85, 98), 2),
                    "error_count": random.randint(0, 5),
                    "warning_count": random.randint(0, 15),
                    "maintenance_required": random.choice([True, False]),
                    "last_maintenance_date": (current_date - timedelta(days=random.randint(1, 30))).strftime("%Y-%m-%d"),
                    "next_maintenance_date": (current_date + timedelta(days=random.randint(1, 30))).strftime("%Y-%m-%d"),
                    "production_units": random.randint(800, 1200),
                    "quality_score": round(random.uniform(0.9, 1.0), 3)
                }
                metrics.append(metric)
        
        return pd.DataFrame(metrics)
    
    def save_data(self, output_dir: str = "./sample_data"):
        """Save all generated data to files"""
        os.makedirs(output_dir, exist_ok=True)
        
        print("Generating sensor data...")
        sensor_df = self.generate_sensor_data()
        sensor_df.to_csv(f"{output_dir}/sensor_data.csv", index=False)
        print(f"Generated {len(sensor_df)} sensor records")
        
        # Split sensor data by date for realistic file structure
        for date in sensor_df['timestamp'].dt.date.unique():
            date_df = sensor_df[sensor_df['timestamp'].dt.date == date]
            date_str = date.strftime("%Y-%m-%d")
            date_dir = f"{output_dir}/sensor_data_by_date/{date_str}"
            os.makedirs(date_dir, exist_ok=True)
            date_df.to_csv(f"{date_dir}/sensor_data_{date_str}.csv", index=False)
        
        print("Generating equipment logs...")
        logs = self.generate_equipment_logs()
        with open(f"{output_dir}/equipment_logs.json", "w") as f:
            json.dump(logs, f, indent=2)
        print(f"Generated {len(logs)} log entries")
        
        # Split logs by date
        logs_by_date = {}
        for log in logs:
            date = log['timestamp'][:10]
            if date not in logs_by_date:
                logs_by_date[date] = []
            logs_by_date[date].append(log)
        
        for date, date_logs in logs_by_date.items():
            date_dir = f"{output_dir}/equipment_logs_by_date/{date}"
            os.makedirs(date_dir, exist_ok=True)
            with open(f"{date_dir}/equipment_logs_{date}.json", "w") as f:
                json.dump(date_logs, f, indent=2)
        
        print("Generating quality metrics...")
        quality_df = self.generate_quality_metrics()
        quality_df.to_csv(f"{output_dir}/quality_metrics.csv", index=False)
        print(f"Generated {len(quality_df)} quality metric records")
        
        # Generate summary statistics
        summary = {
            "generation_date": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "data_period": {
                "start_date": self.start_date.strftime("%Y-%m-%d"),
                "end_date": (self.start_date + timedelta(days=self.num_days)).strftime("%Y-%m-%d"),
                "num_days": self.num_days
            },
            "record_counts": {
                "sensor_readings": len(sensor_df),
                "equipment_logs": len(logs),
                "quality_metrics": len(quality_df)
            },
            "sensors": len(self.sensors),
            "equipment": len(self.equipment)
        }
        
        with open(f"{output_dir}/data_summary.json", "w") as f:
            json.dump(summary, f, indent=2)
        
        print(f"\nData generation completed!")
        print(f"Output directory: {output_dir}")
        print(f"Total sensor readings: {len(sensor_df):,}")
        print(f"Total equipment logs: {len(logs):,}")
        print(f"Total quality metrics: {len(quality_df):,}")


if __name__ == "__main__":
    # Generate sample data for testing
    generator = ManufacturingDataGenerator(
        start_date="2024-01-01",
        num_days=30
    )
    
    generator.save_data("./sample_data")
