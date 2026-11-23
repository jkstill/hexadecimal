-- Drops all demo objects. The hexdump packages are not touched.
drop table hexdump_demo_text purge;
drop table hexdump_demo_long purge;
drop table hexdump_demo_binary purge;
drop table hexdump_demo_long_raw purge;
drop procedure hexdump_demo_load_long_raw;
drop java source "HexdumpDemoLoad";
