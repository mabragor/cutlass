use cutlass;
create table if not exists knot_names (
  knot_id bigint(64) unsigned,
  name varchar(100) character set utf8,
  primary key (knot_id)
);
       