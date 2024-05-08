//
//  Zoom.swift
//  Beckley
//
//  Created by Timothy Larkin on 3/30/19.
//  Copyright © 2019 Abstract Tools. All rights reserved.
//

import Foundation
import Yaz

public struct ZoomConnection {
	public var connection: ZOOM_connection
	var resultSet: ZOOM_resultset?
	public var nResults: Int = 0
	public var results: [Data] = []
	
	public init(path: String ) {
		self.connection = ZOOM_connection_new(path, 0)
		setOption(key: "preferredRecordSyntax", value: "USMARC")
		setOption(key: "charset", value: "marc8")
	}
	
	public func setOption(key: String, value: String) {
		ZOOM_connection_option_set(connection, key, value)
	}
	
	public mutating func getResults(callBack: @escaping([Data])->()) {
		var biteSize: Int = 10
		var start: Int = 0
		while start < nResults {
			if start + biteSize > nResults {
				biteSize = nResults - start
			}
			let zresults = ZoomResults(biteSize)
			zresults.getRecords(self, from: start, count: biteSize)
			var results: [Data] = []
			for i in 0..<biteSize {
				results.append(zresults[i])
			}
			DispatchQueue.main.async {
				callBack(results)
			}

			start += biteSize
		}
		close()
	}
	
	public mutating func doSearch(_ search: ZoomQuery) {
		results = []
		resultSet = ZOOM_connection_search(connection, search.query)
		ZOOM_query_destroy(search.query)
		nResults = ZOOM_resultset_size(resultSet)
	}
	
	public func close() {
		ZOOM_connection_destroy(connection)
	}
}

public struct ZoomResults {
	var records: UnsafeMutablePointer<ZOOM_record?>
	var recordBuffer: UnsafeMutableBufferPointer<ZOOM_record?>
	
	public init(_ count: Int) {
		records = UnsafeMutablePointer<ZOOM_record?>.allocate(capacity: count)
		recordBuffer = UnsafeMutableBufferPointer<ZOOM_record?>(start: records,
																count: count)
	}
	
	subscript(index: Int)->Data {
		var len: Int32 = 0
		if let record = ZOOM_record_get(recordBuffer[index], "raw", &len) {
			let buffer = UnsafeBufferPointer(start: record, count: Int(len))
			let data = Data(buffer: buffer)
			return data
		} else { return Data() }
	}
	
	public func getRecords(_ connection: ZoomConnection, from: Int, count: Int) {
		ZOOM_resultset_records(connection.resultSet, records, from, count)
	}
}

public struct ZoomQuery {
	let query: ZOOM_query
	
	public init(search: String) {
		query = ZOOM_query_create()
		setQuery(search)
	}
	
	public func setQuery(_ search: String) {
		var error_code: Int32 = 0
		var error_pos: Int32 = 0
		let bibset: CCL_bibset = ccl_qual_mk()
		let bibPath = Bundle.main.path(forResource: "remote", ofType: "bib")
		ccl_qual_fname(bibset, bibPath)
		if let result = ccl_find_str(bibset, search, &error_code, &error_pos) {
			let pqf_buf = wrbuf_alloc()
			ccl_pquery(pqf_buf, result)
			pqf_buf?.pointee.buf![(pqf_buf?.pointee.pos)!] = 0
			ccl_rpn_delete(result)
			let pqf_str = pqf_buf?.pointee.buf
			wrbuf_destroy(pqf_buf)
			ZOOM_query_prefix(query, pqf_str)
		}
	}
}

