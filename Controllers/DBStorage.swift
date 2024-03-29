//
//  DBStorage.swift
//  TempAqua
//

import Foundation
import SQLite3
import SwiftUI
import OSLog

var db = DBStorage()
let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

let CREATE_SURVEY_TABLE_SQL = """
CREATE TABLE IF NOT EXISTS
survey
(id TEXT PRIMARY KEY,
 created_at TEXT,
 catchment_id TEXT
);
"""

let CREATE_CATCHMENT_TABLE_SQL = """
CREATE TABLE IF NOT EXISTS
catchment
(id TEXT PRIMARY KEY,
 name TEXT,
 display INTEGER
);
"""

let CREATE_CATCHMENT_LOCATION_TABLE_SQL = """
CREATE TABLE IF NOT EXISTS
catchment_location
(catchment_id TEXT,
 location_id TEXT,
 latitude INTEGER,
 longitude INTEGER,
 equipment TEXT,
 parent TEXT,
 PRIMARY KEY(catchment_id, location_id)
);
"""

let CREATE_SURVEY_OBSERATION_TABLE_SQL = """
CREATE TABLE IF NOT EXISTS
survey_observation
(survey_id TEXT,
 observation_id INTEGER,
 observed_at TEXT,
 category TEXT,
 comment TEXT,
 latitude INTEGER,
 longitude INTEGER,
 accuracy INTEGER,
 gps_device TEXT,
 direction INTEGER,
 elevation INTEGER,
 water_level REAL,
 discharge REAL,
 anchor_point TEXT,
 marker TEXT,
 parent INTEGER,
 PRIMARY KEY(survey_id, observation_id)
);
"""

let CREATE_SURVEY_OBSERATION_MULTIMEDIA_TABLE_SQL = """
CREATE TABLE IF NOT EXISTS
survey_observation_multimedia
(survey_id TEXT,
 observation_id INTEGER,
 taken_at TEXT,
 format TEXT,
 data TEXT,
 PRIMARY KEY(survey_id, observation_id, taken_at)
);
"""

let CREATE_MEDIA_TO_EXPORT_TABLE_SQL = """
CREATE TABLE IF NOT EXISTS
media_to_export
(survey_id TEXT,
 observation_id INTEGER,
 taken_at TEXT,
 format TEXT,
 data TEXT,
 PRIMARY KEY(survey_id, observation_id, taken_at)
);
"""

let CREATE_AUTH_TABLE_SQL = """
CREATE TABLE IF NOT EXISTS
auth
(email TEXT PRIMARY KEY,
 password TEXT,
 url TEXT
);
"""

let CREATE_EMPLOYEE_TABLE_SQL = """
CREATE TABLE IF NOT EXISTS
employee
(id TEXT PRIMARY KEY,
 name TEXT
);
"""

class DBStorage {
    init() {
        db = openDatabase()
        createTable(sql: CREATE_SURVEY_TABLE_SQL)
        createTable(sql: CREATE_CATCHMENT_TABLE_SQL)
        createTable(sql: CREATE_CATCHMENT_LOCATION_TABLE_SQL)
        createTable(sql: CREATE_SURVEY_OBSERATION_TABLE_SQL)
        createTable(sql: CREATE_SURVEY_OBSERATION_MULTIMEDIA_TABLE_SQL)
        createTable(sql: CREATE_MEDIA_TO_EXPORT_TABLE_SQL)
        createTable(sql: CREATE_AUTH_TABLE_SQL)
        createTable(sql: CREATE_EMPLOYEE_TABLE_SQL)
    }

    let dbPath: String = "tempaqua45.sqlite"
    var db:OpaquePointer?

    func openDatabase() -> OpaquePointer? {
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent(dbPath)
        var db: OpaquePointer? = nil
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            Logger().error("Error opening database at \(self.dbPath)")
            return nil
        } else {
            Logger().info("Successfully opened connection to database at \(self.dbPath)")
            return db
        }
    }
    
    func createTable(sql: String) {
        var createTableStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, sql, -1, &createTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(createTableStatement) != SQLITE_DONE {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                Logger().error("Could not create database schema \(errorMessage)")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            Logger().error("CREATE TABLE statement could not be prepared. \(errorMessage)")
        }
        sqlite3_finalize(createTableStatement)
    }
    
    func read() -> [Observation] {
        return read_survey_observations(surveyId: "0")
    }
        
    func insert_employee(employee: Employee) {
        let sql = "INSERT INTO employee (id, name) VALUES (?, ?);"
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            bind_int(queryStatement: statement, index: 1, value: employee.id)
            bind_string(queryStatement: statement, index: 2, value: employee.name)
            if sqlite3_step(statement) != SQLITE_DONE {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                Logger().error("Could not insert employee row: \(errorMessage)")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            Logger().error("Insert survey statement could not be prepared. \(errorMessage)")
        }
        sqlite3_finalize(statement)
    }
    
    func read_employees() -> [Employee] {
        let queryStatementString = "SELECT * FROM employee ORDER BY id;"
        var queryStatement: OpaquePointer? = nil
        var employees: [Employee] = []
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let id = read_int(queryStatement: queryStatement, index: 0)
                let name = read_string(queryStatement: queryStatement, index: 1)
                let employee = Employee(id: id, name: name)
                employees.append(employee)
            }
        } else {
            print("SELECT statement could not be prepared")
        }
        sqlite3_finalize(queryStatement)
        return employees
    }
    
    func removeEmployees() {
        let deleteStatementString = "DELETE FROM employee"
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, deleteStatementString, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Could not delete row.")
            }
        } else {
            print("DELETE statement could not be prepared")
        }
        sqlite3_finalize(statement)
    }
    
    func insert_survey(survey: Survey) {
        let sql = "INSERT INTO survey (id, created_at, catchment_id) VALUES (?, ?, ?);"
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (survey.id as NSString).utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, (ISO8601DateFormatter().string(from: survey.createdAt) as NSString).utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 3, (survey.catchmentId as NSString).utf8String, -1, SQLITE_TRANSIENT)
            if sqlite3_step(statement) != SQLITE_DONE {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                Logger().error("Could not insert survey row: \(errorMessage)")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            Logger().error("Insert survey statement could not be prepared. \(errorMessage)")
        }
        sqlite3_finalize(statement)
    }
    
    func insert_catchment(catchment: Catchment) {
        let sql = "INSERT INTO catchment (id, name, display) VALUES (?, ?, 1);"
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (catchment.id as NSString).utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, (catchment.name as NSString).utf8String, -1, SQLITE_TRANSIENT)
            if sqlite3_step(statement) == SQLITE_DONE {
//                print("Successfully inserted row.")
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("Could not insert row: \(errorMessage)")
            }
            // add all locations
            for location in catchment.locations {
                insert_catchment_location(catchment_id: catchment.id, location: location)
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("INSERT statement could not be prepared. \(errorMessage)")
        }
        sqlite3_finalize(statement)
    }
    
    func update_catchment(catchment_id: String, display: Bool) {
        let sql = """
                     UPDATE catchment SET display = ? WHERE id = ?;
                  """
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            bind_string(queryStatement: statement, index: 2, value: catchment_id)
            var display_int = 1
            if !display {
                display_int = 0
            }
            bind_int(queryStatement: statement, index: 1, value: display_int)
            if sqlite3_step(statement) == SQLITE_DONE {
//                print("Successfully updated row.")
            } else {
                print("Could not update row.")
            }
        } else {
            print("UPDATE statement could not be prepared.")
        }
        sqlite3_finalize(statement)
    }
    
    
    func insert_catchment_location(catchment_id: String, location: CatchmentLocation) {
        let sql = "INSERT INTO catchment_location (catchment_id, location_id, latitude, longitude, equipment, parent) VALUES (?, ?, ?, ?, ?, ?);"
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (catchment_id as NSString).utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, (location.id as NSString).utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_int(statement, 3, Int32(location.latitude))
            sqlite3_bind_int(statement, 4, Int32(location.longitude))
            sqlite3_bind_text(statement, 5, (location.equipment as NSString).utf8String, -1, SQLITE_TRANSIENT)
            bind_string_or_null(queryStatement: statement, index: 6, value: location.parent)
            if sqlite3_step(statement) == SQLITE_DONE {
//                print("Successfully inserted row.")
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("Could not insert row: \(errorMessage)")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("INSERT statement could not be prepared. \(errorMessage)")
        }
        sqlite3_finalize(statement)
    }
    
    func deleteObservationMultimediaFile(surveyId: String, observationId: Int, takenAt: Date) {
        let deleteStatementString = "DELETE FROM survey_observation_multimedia WHERE survey_id=? AND observation_id=? AND taken_at=?;"
        var deleteStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, deleteStatementString, -1, &deleteStatement, nil) == SQLITE_OK {
            bind_string(queryStatement: deleteStatement, index: 1, value: surveyId)
            bind_int(queryStatement: deleteStatement, index: 2, value: observationId)
            bind_date(queryStatement: deleteStatement, index: 3, value: takenAt)
            if sqlite3_step(deleteStatement) != SQLITE_DONE {
                print("Could not delete row.")
            }
        } else {
            print("DELETE statement could not be prepared")
        }
        sqlite3_finalize(deleteStatement)
        
    }
    
    
    func deleteObservationMultimedia(surveyId: String, observationId: Int) {
        let deleteStatementString = "DELETE FROM survey_observation_multimedia WHERE survey_id=? AND observation_id=?;"
        var deleteStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, deleteStatementString, -1, &deleteStatement, nil) == SQLITE_OK {
            bind_string(queryStatement: deleteStatement, index: 1, value: surveyId)
            bind_int(queryStatement: deleteStatement, index: 2, value: observationId)
            if sqlite3_step(deleteStatement) != SQLITE_DONE {
                print("Could not delete row.")
            }
        } else {
            print("DELETE statement could not be prepared")
        }
        sqlite3_finalize(deleteStatement)
    }
    
    func deleteObservation(observation: Observation) {
        let deleteStatementString = "DELETE FROM survey_observation WHERE survey_id='0' AND observation_id=? AND observed_at=?;"
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, deleteStatementString, -1, &statement, nil) == SQLITE_OK {
            bind_int(queryStatement: statement, index: 1, value: observation.id)
            bind_date(queryStatement: statement, index: 2, value: observation.observedAt)
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Could not delete row.")
            } else {
                deleteObservationMultimedia(surveyId: "0", observationId: observation.id)
            }
        } else {
            print("DELETE statement could not be prepared")
        }
        sqlite3_finalize(statement)
    }
    
    func update_survey_observation(survey_id: String, observation: Observation) {
        let sql = """
                     UPDATE survey_observation SET category = ?, comment = ?, latitude = ?, longitude = ?, accuracy = ?, direction = ?, elevation = ?,
                     water_level = ?, discharge = ?, anchor_point = ?, marker = ?, parent = ? WHERE survey_id = ? and observation_id=?;
                  """
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (observation.category.rawValue as NSString).utf8String, -1, nil)
            bind_string_or_null(queryStatement: statement, index: 2, value: observation.comment)
            sqlite3_bind_int(statement, 3, Int32(observation.latitude))
            sqlite3_bind_int(statement, 4, Int32(observation.longitude))
            sqlite3_bind_int(statement, 5, Int32(observation.accuracy))
            bind_int_or_null(queryStatement: statement, index: 6, value: observation.direction)
            bind_int_or_null(queryStatement: statement, index: 7, value: observation.elevation)
            bind_double_or_null(queryStatement: statement, index: 8, value: observation.waterLevel)
            bind_double_or_null(queryStatement: statement, index: 9, value: observation.discharge)
            bind_string_or_null(queryStatement: statement, index: 10, value: observation.anchorPoint)
            sqlite3_bind_text(statement, 11, (observation.marker.rawValue as NSString).utf8String, -1, nil)
            bind_int_or_null(queryStatement: statement, index: 12, value: observation.parent)
            bind_string(queryStatement: statement, index: 13, value: survey_id)
            sqlite3_bind_int(statement, 14, Int32(observation.id))
            if sqlite3_step(statement) == SQLITE_DONE {
//                print("Successfully updated row.")
            } else {
                print("Could not update row.")
            }
        } else {
            print("UPDATE statement could not be prepared.")
        }
        sqlite3_finalize(statement)
        
        // insert photos
        for multimedia in observation.multimedia {
            if !multimedia.persisted {
                insert_multimedia(surveyId: survey_id, observationId: observation.id, multimedia: multimedia)
            }
        }
    }
    
    func insert_survey_observations(survey_id: String, observations: [Observation]) {
        for observation in observations {
            let sql = """
                         INSERT INTO survey_observation
                            (survey_id, observation_id, observed_at, category, comment, latitude, longitude, accuracy, gps_device, direction, elevation, water_level, discharge, anchor_point, marker, parent)
                            VALUES
                            (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
                      """
            var statement: OpaquePointer? = nil
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                bind_string(queryStatement: statement, index: 1, value: survey_id)
                bind_int(queryStatement: statement, index: 2, value: observation.id)
                bind_date(queryStatement: statement, index: 3, value: observation.observedAt)
                bind_string(queryStatement: statement, index: 4, value: observation.category.rawValue)
                bind_string_or_null(queryStatement: statement, index: 5, value: observation.comment)
                bind_int(queryStatement: statement, index: 6, value: observation.latitude)
                bind_int(queryStatement: statement, index: 7, value: observation.longitude)
                bind_int(queryStatement: statement, index: 8, value: observation.accuracy)
                bind_string(queryStatement: statement, index: 9, value: observation.gpsDevice)
                bind_int_or_null(queryStatement: statement, index: 10, value: observation.direction)
                bind_int_or_null(queryStatement: statement, index: 11, value: observation.elevation)
                bind_double_or_null(queryStatement: statement, index: 12, value: observation.waterLevel)
                bind_double_or_null(queryStatement: statement, index: 13, value: observation.discharge)
                bind_string_or_null(queryStatement: statement, index: 14, value: observation.anchorPoint)
                bind_string(queryStatement: statement, index: 15, value: observation.marker.rawValue)
                bind_int_or_null(queryStatement: statement, index: 16, value: observation.parent)

                if sqlite3_step(statement) == SQLITE_DONE {
//                    print("Successfully inserted row.")
                } else {
                    let errorMessage = String(cString: sqlite3_errmsg(db))
                    print("Could not insert row: \(errorMessage)")
                }
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("INSERT statement could not be prepared. \(errorMessage)")
            }
            sqlite3_finalize(statement)
            
            // insert photos
            for multimedia in observation.multimedia {
                insert_multimedia(surveyId: survey_id, observationId: observation.id, multimedia: multimedia)
            }
        }
    }
    
    // reads one observation multimedia
    func read_multimedia_to_export() -> ObservationMultimedia? {
        let queryStatementString = "SELECT survey_id, observation_id, taken_at, format, data FROM media_to_export ORDER BY taken_at ASC LIMIT 1;"
        var queryStatement: OpaquePointer? = nil
        var multimedia: ObservationMultimedia? = nil
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let surveyId = read_string_or_null(queryStatement: queryStatement, index: 0)!
                let observationId = read_int_or_null(queryStatement: queryStatement, index: 1)!
                let takenAt = read_date_or_null(queryStatement: queryStatement, index: 2)!
                let format = read_string_or_null(queryStatement: queryStatement, index: 3)!
                let data = read_string_or_null(queryStatement: queryStatement, index: 4)!
                multimedia = ObservationMultimedia(surveyId: surveyId, observationId: observationId, takenAt: takenAt, format: format, data: data.data(using: .utf8)!)
            }
        } else {
            print("SELECT statement could not be prepared")
        }
        sqlite3_finalize(queryStatement)
        return multimedia
    }
    
    func read_media_to_export() -> [ObservationMultimedia] {
        let queryStatementString = "SELECT survey_id, observation_id, taken_at, format, data FROM media_to_export ORDER BY taken_at ASC;"
        var queryStatement: OpaquePointer? = nil
        var multimediaList: [ObservationMultimedia] = []
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let surveyId = read_string_or_null(queryStatement: queryStatement, index: 0)!
                let observationId = read_int_or_null(queryStatement: queryStatement, index: 1)!
                let takenAt = read_date_or_null(queryStatement: queryStatement, index: 2)!
                let format = read_string_or_null(queryStatement: queryStatement, index: 3)!
                let data = read_string_or_null(queryStatement: queryStatement, index: 4)!
                let multimedia = ObservationMultimedia(surveyId: surveyId, observationId: observationId, takenAt: takenAt, format: format, data: data.data(using: .utf8)!)
                multimediaList.append(multimedia)
            }
        } else {
            print("SELECT statement could not be prepared")
        }
        sqlite3_finalize(queryStatement)
        return multimediaList
    }
    
    func removeFromMediaToExport(multimedia: ObservationMultimedia) {
        let deleteStatementString = "DELETE FROM media_to_export WHERE survey_id=? AND observation_id=? AND taken_at=?;"
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, deleteStatementString, -1, &statement, nil) == SQLITE_OK {
            bind_string(queryStatement: statement, index: 1, value: multimedia.surveyId)
            bind_int(queryStatement: statement, index: 2, value: multimedia.observationId)
            bind_date(queryStatement: statement, index: 3, value: multimedia.takenAt)
            if sqlite3_step(statement) == SQLITE_DONE {
                //print("Successfully deleted row.")
            } else {
                print("Could not delete row.")
            }
        } else {
            print("DELETE statement could not be prepared")
        }
        sqlite3_finalize(statement)
    }
    
    func removeAllMultimediaToExport() {
        let deleteStatementString = "DELETE FROM media_to_export;"
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, deleteStatementString, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                //print("Successfully deleted row.")
            } else {
                print("Could not delete row.")
            }
        } else {
            print("DELETE statement could not be prepared")
        }
        sqlite3_finalize(statement)
    }
    
    func insert_media_to_export(multimediaList: [ObservationMultimedia]) -> Bool {
        for multimedia in multimediaList {
            let sql = """
                         INSERT INTO media_to_export
                            (survey_id, observation_id, taken_at, format, data)
                            VALUES
                            (?, ?, ?, ?, ?);
                      """
            var statement: OpaquePointer? = nil
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                bind_string(queryStatement: statement, index: 1, value: multimedia.surveyId)
                bind_int(queryStatement: statement, index: 2, value: multimedia.observationId)
                bind_date(queryStatement: statement, index: 3, value: multimedia.takenAt)
                bind_string(queryStatement: statement, index: 4, value: multimedia.format)
                bind_string(queryStatement: statement, index: 5, value: multimedia.data.base64EncodedString())
                if sqlite3_step(statement) != SQLITE_DONE {
                    let errorMessage = String(cString: sqlite3_errmsg(db))
                    insert_log(message: "Could not insert multimedia into the export table: \(errorMessage)", status: "ERROR")
                    return false
                }
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("INSERT statement could not be prepared. \(errorMessage)")
                insert_log(message: "Could not insert multimedia into the export table: \(errorMessage)", status: "ERROR")
                return false
            }
            sqlite3_finalize(statement)
        }
        return true
    }
    
    func insert_multimedia(surveyId: String, observationId: Int, multimedia: ObservationMultimedia) {
        let sql = """
                     INSERT INTO survey_observation_multimedia
                        (survey_id, observation_id, taken_at, format, data)
                        VALUES
                        (?, ?, ?, ?, ?);
                  """
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            bind_string(queryStatement: statement, index: 1, value: surveyId)
            bind_int(queryStatement: statement, index: 2, value: observationId)
            bind_date(queryStatement: statement, index: 3, value: multimedia.takenAt)
            bind_string(queryStatement: statement, index: 4, value: multimedia.format)
            bind_string(queryStatement: statement, index: 5, value: multimedia.data.base64EncodedString())

            if sqlite3_step(statement) == SQLITE_DONE {
//                print("Successfully inserted row.")
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("Could not insert row: \(errorMessage)")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("INSERT statement could not be prepared. \(errorMessage)")
        }
        sqlite3_finalize(statement)
    }
    
    func read_surveys() -> [Survey] {
        let queryStatementString = "SELECT * FROM survey ORDER BY created_at DESC;"
        var queryStatement: OpaquePointer? = nil
        var surveys: [Survey] = []
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let surveyId = String(cString: sqlite3_column_text(queryStatement, 0))
                let createdAt = ISO8601DateFormatter().date(from: String(cString: sqlite3_column_text(queryStatement, 1)))!
                let catchmentId = String(cString: sqlite3_column_text(queryStatement, 2))
                let observations = read_survey_observations(surveyId: surveyId)
                let survey = Survey(id: surveyId, createdAt: createdAt, catchmentId: catchmentId, employees: nil, observations: observations)
                surveys.append(survey)
            }
        } else {
            print("SELECT statement could not be prepared")
        }
        sqlite3_finalize(queryStatement)
        return surveys
    }
    
    func remove_surveys() {
        let deleteStatementString = "DELETE FROM survey;"
        var deleteStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, deleteStatementString, -1, &deleteStatement, nil) == SQLITE_OK {
            if sqlite3_step(deleteStatement) == SQLITE_DONE {
//                print("Successfully deleted row.")
            } else {
                print("Could not delete row.")
            }
        } else {
            print("DELETE statement could not be prepared")
        }
        sqlite3_finalize(deleteStatement)
    }
    
    func remove_catchments() {
        let deleteStatementString = "DELETE FROM catchment_location;"
        var deleteStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, deleteStatementString, -1, &deleteStatement, nil) == SQLITE_OK {
            if sqlite3_step(deleteStatement) == SQLITE_DONE {
//                print("Successfully deleted row.")
            } else {
                print("Could not delete row.")
            }
        } else {
            print("DELETE statement could not be prepared")
        }
        sqlite3_finalize(deleteStatement)
        
        let deleteStatementString2 = "DELETE FROM catchment;"
        var deleteStatement2: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, deleteStatementString2, -1, &deleteStatement2, nil) == SQLITE_OK {
            if sqlite3_step(deleteStatement2) == SQLITE_DONE {
    //                print("Successfully deleted row.")
            } else {
                print("Could not delete row.")
            }
        } else {
            print("DELETE statement could not be prepared")
        }
        sqlite3_finalize(deleteStatement2)
    }
    
    func read_auth() -> AuthenticationCredential? {
        let queryStatementString = "SELECT * FROM auth;"
        var queryStatement: OpaquePointer? = nil
        var authenticationCredentials: [AuthenticationCredential] = []
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let email = String(cString: sqlite3_column_text(queryStatement, 0))
                let password = String(cString: sqlite3_column_text(queryStatement, 1))
                let url = String(cString: sqlite3_column_text(queryStatement, 2))
                let auth = AuthenticationCredential(email: email, password: password, url: url)
                authenticationCredentials.append(auth)
            }
        } else {
            print("SELECT statement could not be prepared")
        }
        sqlite3_finalize(queryStatement)
        return authenticationCredentials.first
    }
    
    func read_logs() -> [LogEntry] {
        let queryStatementString = "SELECT * FROM log;"
        var queryStatement: OpaquePointer? = nil
        var logs: [LogEntry] = []
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let message = read_string_or_null(queryStatement: queryStatement, index: 0)!
                let status = read_string_or_null(queryStatement: queryStatement, index: 1)!
                let createdAt = read_date_or_null(queryStatement: queryStatement, index: 2)!

                let logEntry = LogEntry(message: message, status: status, createdAt: createdAt)
                logs.append(logEntry)
            }
        }
        sqlite3_finalize(queryStatement)
        return logs
    }
    
    func delete_auth() {
        let deleteStatementString = "DELETE FROM auth;"
        var statement: OpaquePointer? = nil
        sqlite3_prepare_v2(db, deleteStatementString, -1, &statement, nil);
        sqlite3_step(statement)
        sqlite3_finalize(statement);
    }
    
    func insert_log(message: String, status: String) {
    }
    
    func insert_auth(email: String, password: String, url: String) {
        delete_auth();
        var statement: OpaquePointer? = nil
        let sql = "INSERT INTO auth (email, password, url) VALUES (?, ?, ?);"
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (email as NSString).utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, (password as NSString).utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 3, (url as NSString).utf8String, -1, SQLITE_TRANSIENT)
            if sqlite3_step(statement) != SQLITE_DONE {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                insert_log(message: "Could not insert auth row: \(errorMessage)", status: "ERROR")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            insert_log(message: "Could not prepare insert auth statement: \(errorMessage)", status: "ERROR")
        }
        sqlite3_finalize(statement)
    }
    
    func read_catchments() -> [Catchment] {
        let queryStatementString = "SELECT * FROM catchment ORDER BY name DESC;"
        var queryStatement: OpaquePointer? = nil
        var catchments: [Catchment] = []
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(queryStatement, 0))
                let name = String(cString: sqlite3_column_text(queryStatement, 1))
                let display =  read_int(queryStatement: queryStatement, index: 2)
                let queryStatementString = "SELECT location_id, longitude, latitude, equipment, parent FROM catchment_location WHERE catchment_id = ? ORDER BY location_id;"
                var queryStatement: OpaquePointer? = nil
                var locations: [CatchmentLocation] = []
                if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
                    bind_string(queryStatement: queryStatement, index: 1, value: id)
                    while sqlite3_step(queryStatement) == SQLITE_ROW {
                        let location_id = read_string_or_null(queryStatement: queryStatement, index: 0)!
                        let longitude = read_int_or_null(queryStatement: queryStatement, index: 1) ?? 0
                        let latitude = read_int_or_null(queryStatement: queryStatement, index: 2) ?? 0
                        let equipment = read_string_or_null(queryStatement: queryStatement, index: 3) ?? ""
                        let parent = read_string_or_null(queryStatement: queryStatement, index: 4) ?? ""
                        let catchmentLocation = CatchmentLocation(id: location_id, longitude: longitude, latitude: latitude, equipment: equipment, parent: parent)
                        locations.append(catchmentLocation)
                    }
                }
                let catchment = Catchment(id: id, name: name, display: display == 1, locations: locations)
                catchments.append(catchment)
            }
        } else {
            print("SELECT statement could not be prepared")
        }
        sqlite3_finalize(queryStatement)
        return catchments
    }

    func read_multimedia_list(surveyId: String, observationId: Int) -> [ObservationMultimedia] {
        let queryStatementString = "SELECT taken_at, format, data FROM survey_observation_multimedia WHERE survey_id='\(surveyId)' AND observation_id='\(observationId)' ORDER BY taken_at;"
        var queryStatement: OpaquePointer? = nil
        var multimediaList: [ObservationMultimedia] = []
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let takenAt = read_date_or_null(queryStatement: queryStatement, index: 0)!
                let format = read_string_or_null(queryStatement: queryStatement, index: 1)!
                let data = read_string_or_null(queryStatement: queryStatement, index: 2)!
                let dataBase64 = Data.init(base64Encoded: data)!
//                if format == "jpg" {
//                    let dataDecoded: NSData  = NSData(base64Encoded: dataBase64)!
//                    let uiimage: UIImage = UIImage(data: dataDecoded as Data)!
//                    dataBase64 = uiimage.jpegData(compressionQuality: 0.3)!.base64EncodedData()
//                    //return String(decoding: data.base64EncodedData(), as: UTF8.self)
//                }
                let multimedia = ObservationMultimedia(surveyId: surveyId, observationId: observationId, takenAt: takenAt, format: format, data: dataBase64)
                multimediaList.append(multimedia)
            }
        } else {
            print("SELECT statement could not be prepared")
        }
        sqlite3_finalize(queryStatement)
        return multimediaList
    }
    
    func read_survey_observations(surveyId: String) -> [Observation] {
        let queryStatementString = "SELECT * FROM survey_observation WHERE survey_id='\(surveyId)' ORDER BY observed_at DESC;"
        var queryStatement: OpaquePointer? = nil
        var observations : [Observation] = []
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                var observation = Observation()
                observation.id = Int(sqlite3_column_int(queryStatement, 1))
                observation.observedAt = read_date_or_null(queryStatement: queryStatement, index: 2)!
                observation.category = ObservationCategory(rawValue: read_string_or_null(queryStatement: queryStatement, index: 3)!)!
                observation.comment = read_string_or_null(queryStatement: queryStatement, index: 4)
                observation.latitude = Int(sqlite3_column_int(queryStatement, 5))
                observation.longitude = Int(sqlite3_column_int(queryStatement, 6))
                observation.accuracy = Int(sqlite3_column_int(queryStatement, 7))
                observation.gpsDevice = String(describing: String(cString: sqlite3_column_text(queryStatement, 8)))
                observation.direction = read_int_or_null(queryStatement: queryStatement, index: 9)
                observation.elevation = read_int_or_null(queryStatement: queryStatement, index: 10)
                observation.waterLevel = read_double_or_null(queryStatement: queryStatement, index: 11)
                observation.discharge = read_double_or_null(queryStatement: queryStatement, index: 12)
                observation.anchorPoint = read_string_or_null(queryStatement: queryStatement, index: 13)
                observation.marker = ObservationMarker(rawValue: read_string_or_null(queryStatement: queryStatement, index: 14)!)!
                observation.parent = read_int_or_null(queryStatement: queryStatement, index: 15)
                observation.multimedia = read_multimedia_list(surveyId: surveyId, observationId: observation.id)
                observations.append(observation)
            }
        } else {
            print("SELECT statement could not be prepared")
        }
        sqlite3_finalize(queryStatement)
        return observations
    }
    
    func deleteNewSurvey() {
        let deleteStatementString = "DELETE FROM survey_observation WHERE survey_id=?;"
        var deleteStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, deleteStatementString, -1, &deleteStatement, nil) == SQLITE_OK {
            bind_string(queryStatement: deleteStatement, index: 1, value: "0")
            if sqlite3_step(deleteStatement) != SQLITE_DONE {
                print("Could not delete row.")
            }
        } else {
            print("DELETE statement could not be prepared")
        }
        sqlite3_finalize(deleteStatement)
        
        // delete all multimedia
        if (true) {
            let deleteStatementString = "DELETE FROM survey_observation_multimedia WHERE survey_id=?;"
            var deleteStatement: OpaquePointer? = nil
            if sqlite3_prepare_v2(db, deleteStatementString, -1, &deleteStatement, nil) == SQLITE_OK {
                bind_string(queryStatement: deleteStatement, index: 1, value: "0")
                if sqlite3_step(deleteStatement) != SQLITE_DONE {
                    print("Could not delete row.")
                }
            } else {
                print("DELETE statement could not be prepared")
            }
            sqlite3_finalize(deleteStatement)
        }
    }

    
    func storeNewSurvey(newSurveyId: String) {
        let sql = "UPDATE survey_observation SET survey_id = ? WHERE survey_id = '0';"
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            bind_string(queryStatement: statement, index: 1, value: newSurveyId)
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Could not update row.")
            }
        } else {
            print("UPDATE statement could not be prepared.")
        }
        sqlite3_finalize(statement)
    }
    
    func bind_int_or_null(queryStatement: OpaquePointer?, index: Int, value: Int?) {
        if let unwrapped = value {
            sqlite3_bind_int(queryStatement, Int32(index), Int32(unwrapped))
        } else {
            sqlite3_bind_null(queryStatement, Int32(index))
        }
    }

    func read_int_or_null(queryStatement: OpaquePointer?, index: Int) -> Int? {
        var value: Int? = nil
        if SQLITE_NULL != sqlite3_column_type(queryStatement, Int32(index)) {
            value = Int(sqlite3_column_int(queryStatement, Int32(index)))
        }
        return value
    }
    
    func bind_double_or_null(queryStatement: OpaquePointer?, index: Int, value: Double?) {
        if let unwrapped = value {
            sqlite3_bind_double(queryStatement, Int32(index), Double(unwrapped))
        } else {
            sqlite3_bind_null(queryStatement, Int32(index))
        }
    }
    
    func read_double_or_null(queryStatement: OpaquePointer?, index: Int) -> Double? {
        var value: Double? = nil
        if SQLITE_NULL != sqlite3_column_type(queryStatement, Int32(index)) {
            value = Double(sqlite3_column_double(queryStatement, Int32(index)))
        }
        return value
    }
    
    func bind_date(queryStatement: OpaquePointer?, index: Int, value: Date) {
        sqlite3_bind_text(queryStatement, Int32(index),
                          (ISO8601DateFormatter().string(from: value) as NSString).utf8String, -1, SQLITE_TRANSIENT)
//        let value_string = ISO8601DateFormatter().string(from: value)
//        bind_string(queryStatement: queryStatement, index: index, value: value_string)
    }
    
    func bind_string_or_null(queryStatement: OpaquePointer?, index: Int, value: String?) {
        if let unwrapped = value {
            sqlite3_bind_text(queryStatement, Int32(index), (unwrapped as NSString).utf8String, -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(queryStatement, Int32(index))
        }
    }
    
    func bind_string(queryStatement: OpaquePointer?, index: Int, value: String) {
        sqlite3_bind_text(queryStatement, Int32(index), (value as NSString).utf8String, -1, SQLITE_TRANSIENT)
    }
    
    func bind_int(queryStatement: OpaquePointer?, index: Int, value: Int) {
        sqlite3_bind_int(queryStatement, Int32(index), Int32(value))
    }

    func read_string(queryStatement: OpaquePointer?, index: Int) -> String {
        return String(describing: String(cString: sqlite3_column_text(queryStatement, Int32(index))))
    }
    
    func read_int(queryStatement: OpaquePointer?, index: Int) -> Int {
        return Int(sqlite3_column_int(queryStatement, Int32(index)))
    }
    
    
    func read_string_or_null(queryStatement: OpaquePointer?, index: Int) -> String? {
        var value: String? = nil
        if SQLITE_NULL != sqlite3_column_type(queryStatement, Int32(index)) {
            value = String(describing: String(cString: sqlite3_column_text(queryStatement, Int32(index))))
        }
        return value
    }
    
    func read_date_or_null(queryStatement: OpaquePointer?, index: Int) -> Date? {
        var value: Date? = nil
        if let unwrapped = read_string_or_null(queryStatement: queryStatement, index: index) {
            value = ISO8601DateFormatter().date(from: unwrapped)!
        }
        return value
    }
}
