import json
import sys
from datetime import datetime, timedelta

import pandas as pd
import os
from sodapy import Socrata

try:
    client = Socrata("data.cityofnewyork.us", None)

    today = datetime.now().strftime("%Y-%m-%d")

    one_year_ago = (datetime.now() - timedelta(days=365)).strftime("%Y-%m-%d")
    query = f"SELECT * WHERE crash_date >= '{one_year_ago}' ORDER BY crash_date DESC LIMIT 1000"

    results = client.get("h9gi-nx95", query=query)

    if not results:
        print("Error: No data retrieved!")
        sys.exit(1)

    df = pd.DataFrame.from_records(results)

    if "location" in df.columns:
        df["location"] = df["location"].apply(
            lambda x: json.dumps(x) if isinstance(x, dict) else x
        )

    print(f"Retrieved {len(df)} records")
    print(f"Date range: {df['crash_date'].min()} to {df['crash_date'].max()}")
    print(f"Boroughs represented: {df['borough'].unique().tolist()}")

    column_mapping = {
      "crash_date": "dtime",
      "crash_time": "hour",
      "borough": "borough",
      "latitude": "lat",
      "longitude": "long",
      "number_of_persons_injured": "totInj",
      "number_of_persons_killed": "totKill",
      "number_of_pedestrians_injured": "pedInj",
      "number_of_pedestrians_killed": "pedKill",
      "number_of_cyclist_injured": "cycInj",
      "number_of_cyclist_killed": "cycKill",
      "number_of_motorist_injured": "motInj",
      "number_of_motorist_killed": "motKill",
      "contributing_factor_vehicle_1": "cFactor1",
      "contributing_factor_vehicle_2": "cFactor2",
      "contributing_factor_vehicle_3": "cFactor3",
      "contributing_factor_vehicle_4": "cFactor4",
      "contributing_factor_vehicle_5": "cFactor5",
      "vehicle_type_code1": "vType1",
      "vehicle_type_code2": "vType2",
      "vehicle_type_code_3": "vType3",
      "vehicle_type_code_4": "vType4",
      "vehicle_type_code_5": "vType5"
    }
    df = df.rename(columns=column_mapping)
    
    # Convert date and time
    # Merge date and time into a single datetime column and extract components
    df['dtime'] = pd.to_datetime(df['dtime'] + ' ' + df['hour'], errors='coerce')
    df['year'] = df['dtime'].dt.year
    df['month'] = df['dtime'].dt.month
    df['hour'] = df['dtime'].dt.hour
    df['weekday'] = df['dtime'].dt.weekday + 1  # Convert to 1 (Monday) - 7 (Sunday)

    # Assign severity levels
    def determine_severity(row):
        if int(row['totKill']) > 0:
            return "lethal"
        elif int(row['totInj']) > 0:
            return "injured"
        else:
            return "nohurt"

    df['severity'] = df.apply(determine_severity, axis=1)

    # Select and reorder columns to match ideal_sample format
    final_columns = [
        "borough", "lat", "long", "dtime", "totInj", "totKill", "pedInj", "pedKill",
        "cycInj", "cycKill", "motInj", "motKill", "cFactor1", "cFactor2", "cFactor3", "cFactor4", "cFactor5",
        "vType1", "vType2", "vType3", "vType4", "vType5", "severity", "year", "month", "hour", "weekday"
    ]
    df = df[final_columns]

    # Save the processed data
    script_dir = os.path.dirname(os.path.abspath(__file__))
    parent_dir = os.path.dirname(script_dir)
    output_file = os.path.join(parent_dir, "NYPD_Motor_Vehicle_Collisions_processed.csv")

    df.to_csv(output_file, index=False)

    print(f"Data saved to {output_file}")

    

except Exception as e:
    print(f"Error occurred: {str(e)}")
    sys.exit(1)
