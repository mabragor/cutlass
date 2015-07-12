use cutlass;
create table if not exists 1_homflies (
  knot_id bigint(64) unsigned,
  poly varchar(1000) character set utf8,
  primary key (knot_id),
  key (poly)
);
       