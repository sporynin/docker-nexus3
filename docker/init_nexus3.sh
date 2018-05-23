#!/usr/bin/env bash

init_nexus() {
    . nexus3_utils.sh

    if type -p waitforit > /dev/null; then
        #  -debug
        waitforit -address=tcp://$(nexus_address) -timeout=180
        local nexus_running="$?"
        echo "nexus_running: ${nexus_running}"
        if [ ${nexus_running} -gt 0 ]; then
            echo "nexus is not running"
            exit 1
        fi
    fi

    # 默认用户名/密码 admin/admin123
    nexus_login "admin" "admin123"

    # 设置deployment账户密码
    # see: http://stackoverflow.com/questions/40966763/how-do-i-create-a-user-with-the-a-role-with-the-minimal-set-of-privileges-deploy
    # see: https://books.sonatype.com/nexus-book/reference3/security.html#privileges
    if [ -z "${NEXUS3_DEPLOYMENT_PASSWORD}" ]; then
        NEXUS3_DEPLOYMENT_PASSWORD="deployment"
    fi
    nexus_user "deployment" "${NEXUS3_DEPLOYMENT_PASSWORD}"

    local maven_group_members="maven-releases,maven-snapshots,maven-central"
    # TODO nexus_maven2_hosted "maven-thirdparty" "SNAPSHOT"
    # TODO maven_group_members="${maven_group_members},maven-thirdparty"
    # https://github.com/spring-projects/spring-framework/wiki/Spring-repository-FAQ
    nexus_maven2_proxy "spring-libs-release" "RELEASE" "http://repo.spring.io/libs-release"
    nexus_maven2_proxy "spring-libs-milestone" "RELEASE" "http://repo.spring.io/libs-milestone"
    nexus_maven2_proxy "spring-libs-snapshot" "SNAPSHOT" "http://repo.spring.io/libs-snapshot"
    maven_group_members="${maven_group_members},spring-libs-release,spring-libs-milestone,spring-libs-snapshot"
    nexus_maven2_proxy "spring-release" "RELEASE" "http://repo.spring.io/release"
    nexus_maven2_proxy "spring-milestone" "RELEASE" "http://repo.spring.io/milestone"
    nexus_maven2_proxy "spring-snapshot" "SNAPSHOT" "http://repo.spring.io/snapshot"
    maven_group_members="${maven_group_members},spring-release,spring-milestone,spring-snapshot"
    nexus_maven2_proxy "spring-libs-release-local" "RELEASE" "http://repo.spring.io/libs-release-local"
    nexus_maven2_proxy "spring-libs-milestone-local" "RELEASE" "http://repo.spring.io/libs-milestone-local"
    nexus_maven2_proxy "spring-libs-snapshot-local" "SNAPSHOT" "http://repo.spring.io/libs-snapshot-local"
    maven_group_members="${maven_group_members},spring-libs-release-local,spring-libs-milestone-local,spring-libs-snapshot-local"
    # http://conjars.org
    nexus_maven2_proxy "conjars.org" "RELEASE" "http://conjars.org/repo/"
    maven_group_members="${maven_group_members},conjars.org"
    # https://clojars.org
    nexus_maven2_proxy "clojars.org" "RELEASE" "https://clojars.org/repo/"
    maven_group_members="${maven_group_members},clojars.org"
    # http://www.codehaus.org/mechanics/maven/
    nexus_maven2_proxy "codehaus-mule-repo" "RELEASE" "https://repository-master.mulesoft.org/nexus/content/groups/public/"
    maven_group_members="${maven_group_members},codehaus-mule-repo"
    # http://repo.jenkins-ci.org
    nexus_maven2_proxy "repo.jenkins-ci.org" "RELEASE" "http://repo.jenkins-ci.org/public/"
    maven_group_members="${maven_group_members},repo.jenkins-ci.org"
    # https://developer.jboss.org/wiki/MavenRepository
    nexus_maven2_proxy "org.jboss.repository" "RELEASE" "https://repository.jboss.org/nexus/content/repositories/public/"
    maven_group_members="${maven_group_members},org.jboss.repository"

    # apache snapshots
    nexus_maven2_proxy "apache-snapshots" "SNAPSHOT" "https://repository.apache.org/content/repositories/snapshots/"
    maven_group_members="${maven_group_members},apache-snapshots"

    # sonatype
    nexus_maven2_proxy "sonatype-releases" "RELEASE" "https://oss.sonatype.org/content/repositories/releases/"
    maven_group_members="${maven_group_members},sonatype-releases"
    nexus_maven2_proxy "sonatype-snapshots" "SNAPSHOT" "https://oss.sonatype.org/content/repositories/snapshots/"
    maven_group_members="${maven_group_members},sonatype-snapshots"

    nexus_maven2_proxy "github-chshawkn-wagon-maven-plugin" "RELEASE" "https://raw.github.com/chshawkn/wagon-maven-plugin/mvn-repo/"
    maven_group_members="${maven_group_members},github-chshawkn-wagon-maven-plugin"
    nexus_maven2_proxy "github-chshawkn-maven-settings-decoder" "RELEASE" "https://raw.github.com/chshawkn/maven-settings-decoder/mvn-repo/"
    maven_group_members="${maven_group_members},github-chshawkn-maven-settings-decoder"

    # nexus.internal
    # nexus2 /nexus/content/groups/public/
    if [[ "${INTERNAL_NEXUS2}" == http* ]]; then
        nexus_maven2_proxy "internal-nexus2.snapshot" "SNAPSHOT" "${INTERNAL_NEXUS2}/nexus/content/groups/public/"
        maven_group_members="${maven_group_members},internal-nexus2.snapshot"
        nexus_maven2_proxy "internal-nexus2.release" "RELEASE" "${INTERNAL_NEXUS2}/nexus/content/groups/public/"
        maven_group_members="${maven_group_members},internal-nexus2.release"
    fi
    # nexus3 /nexus/repository/maven-public/
    if [[ "${INTERNAL_NEXUS3}" == http* ]]; then
        nexus_maven2_proxy "internal-nexus3.snapshot" "SNAPSHOT" "${INTERNAL_NEXUS3}/nexus/repository/maven-public/"
        maven_group_members="${maven_group_members},internal-nexus3.snapshot"
        nexus_maven2_proxy "internal-nexus3.release" "RELEASE" "${INTERNAL_NEXUS3}/nexus/repository/maven-public/"
        maven_group_members="${maven_group_members},internal-nexus3.release"
    fi

    nexus_maven_group "maven-public" "${maven_group_members}"

    # Raw Repositories, Maven Sites and More see: https://books.sonatype.com/nexus-book/3.0/reference/raw.html
    #nexus_raw_proxy "npm-dist" "https://nodejs.org/dist/"
    # https://npm.taobao.org/dist is same as https://npm.taobao.org/mirrors/node/
    nexus_raw_proxy "npm-dist-taobao" "https://npm.taobao.org/dist/"
    nexus_raw_proxy "npm-dist-official" "https://nodejs.org/dist/"
    nexus_raw_group "npm-dist" "npm-dist-taobao,npm-dist-official"
    nexus_raw_proxy "npm-sass-taobao" "https://npm.taobao.org/mirrors/node-sass/"
    nexus_raw_proxy "npm-sass-official" "https://github.com/sass/node-sass/releases/"
    nexus_raw_group "npm-sass" "npm-sass-taobao,npm-sass-official"
    nexus_raw_hosted "mvnsite"
    nexus_raw_hosted "files"

    # see: https://books.sonatype.com/nexus-book/3.0/reference/docker.html
    nexus_docker_hosted "docker-hosted" "http" "5000"
    local docker_registries=""
    #docker_registries="${docker_registries},docker-hosted"
    nexus_docker_proxy "docker-central-hub" "http" "5003" "https://registry-1.docker.io" "HUB"
    docker_registries="${docker_registries},docker-central-hub"
    if [ ! -z "${DOCKER_MIRROR_GCR}" ]; then
        nexus_docker_proxy "docker-mirror-gcr" "http" "5004" "${DOCKER_MIRROR_GCR}" "REGISTRY"
        docker_registries="${docker_registries},docker-mirror-gcr"
    fi
    nexus_docker_proxy "docker-central-163" "http" "5002" "http://hub-mirror.c.163.com" "HUB"
    docker_registries="${docker_registries},docker-central-163"
    nexus_docker_group "docker-public" "http" "5001" "${docker_registries}"

    # proxy https://registry.npmjs.org, see: https://books.sonatype.com/nexus-book/3.0/reference/npm.html
    nexus_npm_proxy "npm-central-taobao" "https://registry.npm.taobao.org"
    nexus_npm_proxy "npm-central-official" "https://registry.npmjs.org"
    nexus_npm_hosted "npm-hosted"
    nexus_npm_group "npm-public" "npm-hosted,npm-central-taobao,npm-central-official"

    # see: https://books.sonatype.com/nexus-book/3.0/reference/bower.html
    nexus_bower_proxy "bower-central" "http://bower.herokuapp.com"
    nexus_bower_hosted "bower-hosted"
    nexus_bower_group "bower-public" "bower-hosted,bower-central"

    # proxy https://pypi.python.org/pypi, see: https://books.sonatype.com/nexus-book/3.0/reference/pypi.html
    # proxy rubygems.org, see: https://books.sonatype.com/nexus-book/3.0/reference/rubygems.html

    echo "init_nexus done"
}

echo "init_nexus3.sh pwd: $(pwd)"
init_nexus

if [ ! -z "${NEXUS3_PORT}" ] && [ "${NEXUS3_PORT}" != "8081" ]; then
    socat TCP-LISTEN:${NEXUS3_PORT},fork TCP:127.0.0.1:8081 &
fi
