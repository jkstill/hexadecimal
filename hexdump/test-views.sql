
set long 1000000

drop table test_views purge;

create table test_views (view_name varchar2(30), view_text clob);

insert into test_views
values('DBA_USERS',
q'[
select u.name, u.user#,
     decode(u.password, 'GLOBAL', u.password,
                        'EXTERNAL', u.password,
                        NULL),
     m.status,
     decode(mod(u.astatus, 16), 4, u.ltime,
                                5, u.ltime,
                                6, u.ltime,
                                8, u.ltime,
                                9, u.ltime,
                                10, u.ltime, to_date(NULL)),
     decode(mod(u.astatus, 16),
            1, u.exptime,
            2, u.exptime,
            5, u.exptime,
            6, u.exptime,
            9, u.exptime,
            10, u.exptime,
            decode(u.password, 'GLOBAL', to_date(NULL),
                               'EXTERNAL', to_date(NULL),
              decode(u.ptime, '', to_date(NULL),
                decode(pr.limit#, 2147483647, to_date(NULL),
                 decode(pr.limit#, 0,
                   decode(dp.limit#, 2147483647, to_date(NULL), u.ptime +
                     dp.limit#/86400),
                   u.ptime + pr.limit#/86400))))),
     dts.name, tts.name, ltts.name,
     u.ctime, p.name,
     nvl(cgm.consumer_group, 'DEFAULT_CONSUMER_GROUP'),
     u.ext_username,
     decode(bitand(u.spare1, 65536), 65536, NULL, decode(
       REGEXP_INSTR(
         NVL2(u.password, u.password, ' '),
         '^                $'
       ),
       0,
       decode(length(u.password), 16, '10G ', NULL),
       ''
     ) ||
     decode(
       REGEXP_INSTR(
         REGEXP_REPLACE(
           NVL2(u.spare4, u.spare4, ' '),
           'S:000000000000000000000000000000000000000000000000000000000000',
           'not_a_verifier'
         ),
         'S:'
       ),
       0, '', '11G '
     ) ||
     decode(
       REGEXP_INSTR(
         NVL2(u.spare4, u.spare4, ' '),
         'T:'
       ),
       0, '', '12C '
     ) ||
     decode(
       REGEXP_INSTR(
         REGEXP_REPLACE(
           NVL2(u.spare4, u.spare4, ' '),
           'H:00000000000000000000000000000000',
           'not_a_verifier'
         ),
         'H:'
       ),
       0, '', 'HTTP '
     )),
     decode(bitand(u.spare1, 16),
            16, 'Y',
                'N'),
     decode(bitand(u.spare1,65536), 65536, 'NONE',
                   decode(u.password, 'GLOBAL',   'GLOBAL',
                                      'EXTERNAL', 'EXTERNAL',
                                      'PASSWORD')),
     decode(bitand(u.spare1, 10272),
            32, 'Y', 2048, 'Y',  2080, 'Y',
          8192, 'Y', 8224, 'Y', 10240, 'Y',
         10272, 'Y',
                'N'),
     decode(bitand(u.spare1, 128), 0, 'NO', 'YES'),
    from_tz(to_timestamp(to_char(u.spare6, 'DD-MON-YYYY HH24:MI:SS'),
                          'DD-MON-YYYY HH24:MI:SS'), '0:00')
     at time zone sessiontimezone,
     decode(bitand(u.spare1, 256), 256, 'Y', 'N'),
     decode(bitand(u.spare1, 4224),
            128, decode(SYS_CONTEXT('USERENV', 'CON_ID'), 1, 'NO', 'YES'),
            4224, decode(SYS_CONTEXT('USERENV', 'IS_APPLICATION_PDB'),
                         'YES', 'YES', 'NO'),
            'NO'),
     nls_collation_name(nvl(u.spare3, 16382)),
     -- IMPLICIT
     decode(bitand(u.spare1, 32768), 32768, 'YES', 'NO'),
     -- ALL_SHARD
     decode(bitand(u.spare1, 16384), 16384, 'YES', 'NO'),
     -- PASSWORD_CHANGE_DATE
]')
/


commit;

select * from test_views;


