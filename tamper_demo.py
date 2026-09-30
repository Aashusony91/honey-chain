import sqlite3
import json

DB_PATH = "madhur_trace.db"

def tamper_latest_report():
    print("🐝 Connecting to HoneyChain Database...")
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    # Get the most recent report
    cursor.execute("SELECT id, report_payload, report_hash FROM reports ORDER BY id DESC LIMIT 1")
    row = cursor.fetchone()
    
    if not row:
        print("❌ No reports found in the database. Please submit a harvest first.")
        return

    report_id, payload_str, report_hash = row
    print(f"\n✅ Found Latest Report: ID {report_id}")
    print(f"🔗 Original Hash: {report_hash}")

    # Parse JSON and tamper with the data
    payload = json.loads(payload_str)
    old_weight = payload.get("harvest_weight_kg", 0)
    
    print(f"\n🕵️‍♂️ TAMPERING WITH DATA...")
    print(f"   Original Weight: {old_weight} kg")
    
    # Change the weight to fake data
    fake_weight = old_weight + 500.0  
    payload["harvest_weight_kg"] = fake_weight
    
    print(f"   Tampered Weight: {fake_weight} kg")

    # Save the tampered JSON back to the database
    # (Without updating the report_hash column, simulating a database hack)
    new_payload_str = json.dumps(payload)
    
    cursor.execute(
        "UPDATE reports SET report_payload = ? WHERE id = ?", 
        (new_payload_str, report_id)
    )
    conn.commit()
    conn.close()

    print("\n🚨 DATA TAMPERED SUCCESSFULLY!")
    print("   Go to the UI and refresh the 'View Public On-Chain Proof' page.")
    print(f"   URL: http://localhost:3000/verify/{report_hash}")
    print("   The system should now catch the mismatch and show a RED 'NOT VERIFIED' warning!")

if __name__ == "__main__":
    tamper_latest_report()
