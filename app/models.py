from sqlalchemy import (
    Column,
    Integer,
    String,
    ARRAY,
    DateTime,
    Enum,
    Float,
    Double,
    ForeignKey,
    Boolean,
)
from sqlalchemy.orm import declarative_base

from schemas.group import GroupTypeEnum

Base = declarative_base()


class User(Base):
    __tablename__ = "users"
    uid = Column(String, primary_key=True, index=True)
    first_name = Column(String)
    last_name = Column(String)
    email_address = Column(String)
    phone_number = Column(String)
    groups = Column(ARRAY(Integer))
    profile_image_url = Column(String)

class Group(Base):
    __tablename__ = "groups"
    gid = Column(Integer, primary_key=True, index=True)
    members = Column(ARRAY(Integer))
    owner = Column(String)
    admin = Column(ARRAY(Integer))
    group_name = Column(String)
    location_lat = Column(Double)
    location_long = Column(Double)
    group_type = Column(Enum(GroupTypeEnum, name="group_type"))

class Trip(Base):
    __tablename__ = "trips"
    tid = Column(Integer, primary_key=True, index=True)
    group = Column(Integer)
    location_lat = Column(Double)
    location_long = Column(Double)

##class Random(Base):

##class Planned(Base):
