-module(querly_db_tests).
-author('Dan Mohl').

-export([run_all/0, test_build_record/0, test_build_json/0, test_create_person_doc/0,
		test_get_all_docs/0, test_should_return_expected_person_record/0, test_should_load_person_records/0, test_get_database_names/0, 
		test_db_should_exist/0, test_get_table_by_name_with_table_found/0, test_get_table_by_name_with_table_not_found/0,
		test_should_load_employer_records/0, test_chop_nonprintable_characters/0]).
		 
-include_lib("../src/record_definitions.hrl").

get_test_db_name() ->
	"test_general_person_db".
	
delete_test_db() ->
    ecouch:db_delete(get_test_db_name()).

initialize_test_suite() ->
    querly_db:start(),	
	delete_test_db().

finalize_test_suite() ->
    delete_test_db().

run_all() ->
	% initialize tests
	initialize_test_suite(),
	% all tests
	test_build_json(),
	test_build_record(),
	test_create_person_doc(),
	test_get_all_docs(),
	test_should_return_expected_person_record(),
	test_get_database_names(),
	test_db_should_exist(),
	test_get_table_by_name_with_table_found(),
	test_get_table_by_name_with_table_not_found(),
	test_should_load_person_records(),
	test_should_load_employer_records(),
	test_chop_nonprintable_characters(),
	% cleanup
	finalize_test_suite().
	
test_build_json() ->
	Json = {obj, [{"Idno", 1}, {"FirstName", "Dan"}, {"LastName", "Mohl"}, {"Dob", "08/28/1977"}, {"Ssn", "123-45-9876"}]},
    RecordToTransform = #person{'Idno'=1, 'FirstName'="Dan", 'LastName'="Mohl", 'Dob'="08/28/1977", 'Ssn'="123-45-9876"},
	Result = querly_db:build_json(RecordToTransform, ?personFields),
	test_helper:display_message({"querly_db_tests/test_build_json", Result == Json, Result}).

test_build_record() ->
	Json = {obj, [{"Idno", 1}, {"FirstName", "Dan"}, {"LastName", "Mohl"}, {"Dob", "08/28/1977"}, {"Ssn", "123-45-9876"}]},
    PersonRecord = #person{'Idno'=1, 'FirstName'="Dan", 'LastName'="Mohl", 'Dob'="08/28/1977", 'Ssn'="123-45-9876"},
	DefaultRecord = #person{},
	Result = querly_db:build_record(Json, DefaultRecord, ?personFields),
	test_helper:display_message({"querly_db_tests/test_build_record", Result == PersonRecord, Result}).
	
test_create_person_doc() ->	
	PersonRecord = #person{'Idno'=99999997, 'FirstName'="Dan", 'LastName'="Mohl", 'Dob'="08/28/1977", 'Ssn'="123-45-9876"},
	Result = querly_db:doc_create(get_test_db_name(), "2", PersonRecord, ?personFields),
	test_helper:display_message({"querly_db_tests/test_create_person_doc", element(1, Result) == ok, element(2, Result)}).
	
test_get_all_docs() ->
	PersonRecord = #person{'Idno'=99999998, 'FirstName'="Dan2", 'LastName'="Mohl", 'Dob'="08/28/1977", 'Ssn'="123-45-9876"},
	querly_db:doc_create(get_test_db_name(), "3", PersonRecord, ?personFields),
	Result = querly_db:doc_get_all(get_test_db_name()),
	test_helper:display_message({"querly_db_tests/test_get_all_docs", element(1, Result) == ok, element(2, Result)}).

test_should_return_expected_person_record() ->	
	PersonRecord = #person{'Idno'=99999999, 'FirstName'="Dan", 'LastName'="Mohl", 'Dob'="08/28/1977", 'Ssn'="123-45-9876"},
	querly_db:doc_create(get_test_db_name(), "999", PersonRecord, ?personFields),
	ResultJson = element(2, querly_db:doc_get(get_test_db_name(), "999")),
	Result = querly_db:build_record(ResultJson, PersonRecord, ?personFields),
	test_helper:display_message({"querly_db_tests/test_should_return_expected_person_record", Result == PersonRecord, Result}).
	
test_get_database_names() ->
	ecouch:db_create("test_get_database_names_1"),
	ecouch:db_create("test_get_database_names_2"),
	ecouch:db_create("test_get_database_names_3"),
	DatabaseNameList = querly_db:get_database_names(),
	Result = erlang:length(DatabaseNameList),
	ecouch:db_delete("test_get_database_names_1"),
	ecouch:db_delete("test_get_database_names_2"),
	ecouch:db_delete("test_get_database_names_3"),
	test_helper:display_message({"querly_db_tests/test_get_database_names", Result >= 3, Result}).

test_db_should_exist() ->
	ecouch:db_create("person_exist"),
    Result = querly_db:db_exists("person_exist"),
	ecouch:db_delete("person_exist"),
	test_helper:display_message({"querly_db_tests/test_db_should_exist", Result == true, Result}).

test_get_table_by_name_with_table_found() ->
	PersonTable = ets:new(table, [{keypos, 1}]),
	CustomerTable = ets:new(table, [{keypos, 1}]),
	TableList = [{"person", PersonTable}, {"customer", CustomerTable}],
	Result = querly_db:get_table_by_name("customer", TableList), 
   	test_helper:display_message({"querly_db_tests/test_get_table_by_name_with_table_found", Result == CustomerTable, Result}).
    	
test_get_table_by_name_with_table_not_found() ->
	PersonTable = ets:new(table, [{keypos, 1}]),
	TableList = [{"person", PersonTable}, {"person2", PersonTable}],
	Result = querly_db:get_table_by_name("person3", TableList), 
   	test_helper:display_message({"querly_db_tests/test_get_table_by_name_with_table_not_found", Result  == undefined, Result}).

test_should_load_person_records() ->
	PersonRecord1 = #person{'Idno'=1, 'FirstName'="Dan", 'LastName'="Mohl", 'Dob'="08/28/1977", 'Ssn'="123-45-9876"},
	PersonRecord2 = #person{'Idno'=2, 'FirstName'="Dan2", 'LastName'="Mohl", 'Dob'="08/28/1977", 'Ssn'="123-45-9876"},
	PersonRecord3 = #person{'Idno'=3, 'FirstName'="Dan3", 'LastName'="Mohl", 'Dob'="08/28/1977", 'Ssn'="123-45-9876"},
	querly_db:doc_create("test_person_db", "1", PersonRecord1, ?personFields),
	querly_db:doc_create("test_person_db", "2", PersonRecord2, ?personFields),
	querly_db:doc_create("test_person_db", "3", PersonRecord3, ?personFields),
	Pid = spawn(querly_db, tables_service, [{"test_~s_db", []}]),
	Pid ! {self(), get_table, person, #person.'Idno'},
	receive
		{table_results, Table} ->
			People = Table;
		_Received -> 
			io:format("~p~n~n", [_Received]),
			People = ets:new(table, [{keypos, #person.'Idno'}])
	end,
	Result = ets:select(People, [{#person{_ = '_'}, [], ['$_']}]),
	test_helper:display_message({"querly_db_tests/test_should_load_person_records", erlang:length(Result) == 3, erlang:length(Result)}),
	ecouch:db_delete("test_person_db").

test_should_load_employer_records() ->
	Record1 = #employer{'Id'=1, 'Name'="ABC Corp.", 'Address'="123 South, Nashville, IN, 98766"},
	Record2 = #employer{'Id'=2, 'Name'="123 Inc.", 'Address'="321 Main, Nsh, TN 30727"},
	querly_db:doc_create("test_employer_db", "1", Record1, ?employerFields),
	querly_db:doc_create("test_employer_db", "2", Record2, ?employerFields),
	Pid = spawn(querly_db, tables_service, [{"test_~s_db", []}]),
	Pid ! {self(), get_table, employer, #employer.'Id'},
	receive
		{table_results, Table} ->
			Employer = Table;
		_Received -> 
			io:format("~p", [_Received]),
			Employer = ets:new(table, [{keypos, #employer.'Id'}])
	end,
	Result = ets:select(Employer, [{#employer{_ = '_'}, [], ['$_']}]),
	test_helper:display_message({"querly_db_tests/test_should_load_employer_records", erlang:length(Result) == 2, erlang:length(Result)}),
	ecouch:db_delete("test_employer_db").

test_chop_nonprintable_characters() ->
    Result = querly_db:chop_nonprintable_characters([0,1,200, 175, 100, 4, 100]),
	test_helper:display_message({"querly_db_tests/test_chop_nonprintable_characters", Result == "dd", Result}).
	