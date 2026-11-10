import os
import pymysql
from flask import Flask, jsonify, request, send_from_directory
from dotenv import load_dotenv

load_dotenv()
app = Flask(__name__, static_folder="static")


def get_db():
    return pymysql.connect(host=os.environ["DB_HOST"],
                           port=int(os.environ["DB_PORT"]),
                           user=os.environ["DB_USER"],
                           password=os.environ["DB_PASSWORD"],
                           database=os.environ["DB_NAME"],
                           cursorclass=pymysql.cursors.DictCursor)

def run_query(sql, params=()):
    conn = get_db()
    try:
        cur = conn.cursor()
        cur.execute(sql, params)
        result = cur.fetchall()
        return result
    finally:
        conn.close()



@app.route("/")
def home():
    return send_from_directory(app.static_folder, "index.html")


@app.route("/api/health")
def health():
    sql = """SELECT DATABASE() AS db, VERSION() AS version,
             (SELECT COUNT(*) FROM Driver) AS drivers,
             (SELECT COUNT(*) FROM Race) AS races,
             (SELECT COUNT(*) FROM Circuit) AS circuits,
             (SELECT COUNT(*) FROM Constructor) AS constructors"""
    return jsonify(run_query(sql)[0])


@app.route("/api/drivers")
def search_drivers():
    name = request.args.get("q", "").strip()
    search = "%" + name + "%"
    sql = """
    SELECT d.driverId, d.forename, d.surname, d.code, d.nationality, d.dateOfBirth,
           COUNT(rr.raceId) AS wins
    FROM Driver d
    LEFT JOIN RaceResult rr ON rr.driverId = d.driverId AND rr.finishPosition = 1
    WHERE d.forename LIKE %s OR d.surname LIKE %s OR CONCAT(d.forename, ' ', d.surname) LIKE %s
    GROUP BY d.driverId, d.forename, d.surname, d.code, d.nationality, d.dateOfBirth
    ORDER BY wins DESC, d.surname
    LIMIT 25
    """
    drivers = run_query(sql, (search, search, search))
    for d in drivers:
        if d["dateOfBirth"]:
            d["dateOfBirth"] = str(d["dateOfBirth"])
    return jsonify(drivers)

@app.route("/api/circuit-kings")
def circuit_kings():
    sql = """
    SELECT c.name AS circuit, d.forename, d.surname, COUNT(*) AS wins
    FROM RaceResult rr
    JOIN Race r ON r.raceId = rr.raceId
    JOIN Circuit c ON c.circuitId = r.circuitId
    JOIN Driver d ON d.driverId = rr.driverId
    WHERE rr.finishPosition = 1
    GROUP BY c.circuitId, c.name, d.driverId, d.forename, d.surname
    HAVING COUNT(*) = 
    (SELECT COUNT(*) FROM RaceResult rr2
    JOIN Race r2 ON r2.raceId = rr2.raceId
    WHERE rr2.finishPosition = 1 AND r2.circuitId = c.circuitId
    GROUP BY rr2.driverId
    ORDER BY COUNT(*) DESC
    LIMIT 1)
    ORDER BY wins DESC, circuit
    LIMIT 15
    """
    return jsonify(run_query(sql))


@app.route("/api/quizzes", methods=["GET"])
def get_quizzes():
    quizzes = run_query("SELECT quizId, title, description, category, eraStartYear, eraEndYear, createdAt "
                        "FROM Quiz WHERE quizType = 'CUSTOM' ORDER BY quizId DESC")
    for q in quizzes:
        if q["createdAt"]:
            q["createdAt"] = str(q["createdAt"])
    return jsonify(quizzes)


def year_or_none(val):
    if val is None or str(val).strip() == "":
        return None
    return int(val)


@app.route("/api/quizzes", methods=["POST"])
def create_quiz():
    data = request.get_json(force=True)
    title = (data.get("title") or "").strip()
    if title == "":
        return jsonify({"error": "Title is required"}), 400

    conn = get_db()
    try:
        cur = conn.cursor()
        cur.execute("SELECT COALESCE(MAX(quizId), 0) + 1 AS nextId FROM Quiz FOR UPDATE")
        new_id = cur.fetchone()["nextId"]
        cur.execute("INSERT INTO Quiz (quizId, ownerId, title, description, quizType, visibility, category, eraStartYear, eraEndYear) "
                    "VALUES (%s, NULL, %s, %s, 'CUSTOM', 'PUBLIC', %s, %s, %s)",
                    (new_id, title, data.get("description") or None, data.get("category") or None,
                     year_or_none(data.get("eraStartYear")), year_or_none(data.get("eraEndYear"))))
        conn.commit()
    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        conn.close()

    return jsonify({"quizId": new_id}), 201


@app.route("/api/quizzes/<int:quiz_id>", methods=["PUT"])
def update_quiz(quiz_id):
    data = request.get_json(force=True)
    title = (data.get("title") or "").strip()
    if title == "":
        return jsonify({"error": "Title is required"}), 400
    conn = get_db()
    try:
        cur = conn.cursor()
        rows = cur.execute("UPDATE Quiz SET title = %s, description = %s WHERE quizId = %s AND quizType = 'CUSTOM'",
                           (title, data.get("description") or None, quiz_id))
        conn.commit()
    finally:
        conn.close()
    if rows == 0:
        return jsonify({"error": "Quiz not found"}), 404
    return jsonify({"updated": quiz_id})



@app.route("/api/quizzes/<int:quiz_id>", methods=["DELETE"])
def delete_quiz(quiz_id):
    conn = get_db()
    try:
        cur = conn.cursor()
        cur.execute("DELETE aa FROM AttemptAnswer aa JOIN QuizAttempt qa ON qa.attemptId = aa.attemptId WHERE qa.quizId = %s", (quiz_id,))
        cur.execute("DELETE FROM QuizAttempt WHERE quizId = %s", (quiz_id,))
        cur.execute("DELETE FROM QuizQuestion WHERE quizId = %s", (quiz_id,))
        rows = cur.execute("DELETE FROM Quiz WHERE quizId = %s AND quizType = 'CUSTOM'", (quiz_id,))
        conn.commit()
    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        conn.close()

    if rows == 0:
        return jsonify({"error": "Quiz not found"}), 404
    return jsonify({"deleted": quiz_id})


if __name__ == "__main__":
    app.run(debug=True, port=5000)
