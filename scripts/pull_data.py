import json
import sys
from datetime import datetime, timedelta

import pandas as pd
import os
from sodapy import Socrata

try:
    client = Socrata("data.cityofnewyork.us", None)

    today = datetime.now().strftime("%Y-%m-%d")

    seven_days_ago = (datetime.now() - timedelta(days=7)).strftime("%Y-%m-%d")
    query = f"SELECT * WHERE crash_date >= '{seven_days_ago}' ORDER BY crash_date DESC LIMIT 1000"

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

    script_dir = os.path.dirname(os.path.abspath(__file__))
    parent_dir = os.path.dirname(script_dir)
    output_file = os.path.join(parent_dir, "NYPD_Motor_Vehicle_Collisions_processed.csv")

    df.to_csv(output_file, index=False)

    print(f"Data saved to {output_file}")

    

except Exception as e:
    print(f"Error occurred: {str(e)}")
    sys.exit(1)
