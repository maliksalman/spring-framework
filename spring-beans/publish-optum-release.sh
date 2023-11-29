#!/bin/bash

SRC_VER="4.3.30.RELEASE"
LOCAL_MVN_CACHE="${HOME}/.m2/repository"
DST_VER="4.3.30.optum-1.RELEASE"
WORKSPACE=$(dirname $PWD)

# verify all the required tools are installed
which -s gradle zip xmlstarlet sha1sum
if [[ $? != 0 ]]; then
  echo "One of the required tools are missing: gradle zip xmlstarlet sha1sum"
  exit 1
fi

# compile the code
gradle clean assemble

# create the destination
DST=${LOCAL_MVN_CACHE}/org/springframework/spring-beans/${DST_VER}
rm -rf ${DST}
mkdir -p ${DST}

# copy over the javadoc jar
cp ${LOCAL_MVN_CACHE}/org/springframework/spring-beans/${SRC_VER}/spring-beans-${SRC_VER}-javadoc.jar ${DST}/spring-beans-${DST_VER}-javadoc.jar

# patch the sources
cp ${LOCAL_MVN_CACHE}/org/springframework/spring-beans/${SRC_VER}/spring-beans-${SRC_VER}-sources.jar ${DST}/spring-beans-${DST_VER}-sources.jar
pushd ${WORKSPACE}/spring-beans/src/main/java
zip ${DST}/spring-beans-${DST_VER}-sources.jar org/springframework/beans/CachedIntrospectionResults.java
popd

# patch the lib - with class changes
cp ${LOCAL_MVN_CACHE}/org/springframework/spring-beans/${SRC_VER}/spring-beans-${SRC_VER}.jar ${DST}/spring-beans-${DST_VER}.jar
pushd ${WORKSPACE}/spring-beans/build/classes/java/main
zip ${DST}/spring-beans-${DST_VER}.jar org/springframework/beans/CachedIntrospectionResults.class
popd

# patch the lib - with manifest changes
mkdir META-INF
echo "Manifest-Version: 1.0
Implementation-Title: spring-beans
Implementation-Version: ${DST_VER}
Created-By: 1.8.0_392" > META-INF/MANIFEST.MF
zip ${DST}/spring-beans-${DST_VER}.jar META-INF/MANIFEST.MF
rm -rf META-INF

# create the pom.xml
cp ${LOCAL_MVN_CACHE}/org/springframework/spring-beans/${SRC_VER}/spring-beans-${SRC_VER}.pom ${DST}/spring-beans-${DST_VER}.pom
xmlstarlet edit -L -N w=http://maven.apache.org/POM/4.0.0 \
    -u "//w:project/w:version" \
    -v "${DST_VER}" \
    ${DST}/spring-beans-${DST_VER}.pom

# create the sha1 sums
for NM in .pom -sources.jar -javadoc.jar .jar; do
    SUM=$(sha1sum ${DST}/spring-beans-${DST_VER}${NM} | cut -d ' ' -f 1)
    echo -n "$SUM" > ${DST}/spring-beans-${DST_VER}${NM}.sha1
done

# some useful info
echo
echo Published artifacts in ${DST}
echo