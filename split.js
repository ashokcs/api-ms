const axios = require('axios')
const fs = require('fs')
const YAML = require('yaml')

const srcServices = {
    accounts: '52.167.62.186',
    cards: '40.79.18.220',
    identityprovider: '40.123.26.42',
    notifications: '52.179.169.65',
    notificationprovider: '52.167.63.98',
    paymentkyc: '52.147.169.246',
    payments: '52.179.131.53',
    transactions: '40.70.202.107',
    users: '40.70.68.63'
}

async function download(url) {
    try {
        let response = await axios.get(url)
        console.error(`Downloaded ${url}`)
        return response.data
    } catch(e) {
        console.error(`Could not download ${url}`)
    }
}

async function processMs (ms, msIp) {
    let data = await download(`http://${msIp}:8080/v2/api-docs`)
    if (!data) return
    data.info.title = data.info.title + ' - ' + ms
    return data
}

async function readApiDocumentation() {
    let api = {
        paths: {}
    }
    let keys = Object.keys(srcServices)
    for (let i = 0; i < keys.length; i++) {
        let ms = keys[i]
        let msIp = srcServices[ms]
        let msSwagger = await processMs(ms, msIp)
        if (!msSwagger) continue
        api[ms] = {
            originalSwagger: msSwagger,
            used: false
        }
        Object.keys(msSwagger.paths).filter(v => v.startsWith('/v1')).forEach(path => {
            api.paths[path] = ms
        })
    }
    return api
}

class ApiManagerDefinition {
    constructor(originalSwagger) {
        this.originalSwagger = originalSwagger
        this.paths = Object.keys(originalSwagger.paths)
        this.definitions = Object.keys(originalSwagger.definitions)
    }

    getPath(path) {
        return this.originalSwagger.paths[path]
    }

    getDefinition(name) {
        return this.originalSwagger.definitions[name]
    }
}

class SwaggerDefinition {
    constructor(name) {
        this.swagger = '2.0'
        this.info = {
            version: '1.0.0',
            title: name.charAt(0).toUpperCase() + name.slice(1) + ' API'
        }
        this.host = '170.0.1.1:8080'
        this.schemes = ['http']
        this.paths = {}
        this.definitions = {}
    }
}

async function processStaticFile() {
    const file = fs.readFileSync('./tenpo-api-management-dev.yaml', 'utf8')
    const y = YAML.parse(file)

    return new ApiManagerDefinition(y)
}

function checkDefinition(definition) {
}

async function main () {
    let apiDocs = await readApiDocumentation()
    let apiManager = await processStaticFile()

    let brokenPaths = []

    let result = {}

    apiManager.paths.forEach(path => {
        let msName = apiDocs.paths[path]
        if (!msName) {
            brokenPaths.push(path)
            return
        }
        if (!result[msName]) result[msName] = new SwaggerDefinition(msName)
        result[msName].paths[path] = apiManager.getPath(path)
        Object.values(result[msName].paths[path]).forEach(methodConfiguration => {
            // check parameters for definitions
            if (methodConfiguration.parameters)
                methodConfiguration.parameters.filter(v => v.in == 'body')
                    .map(v => v.schema['$ref'].replace('#/definitions/', ''))
                    .forEach(ref => result[msName].definitions[ref] = apiManager.getDefinition(ref))

            // check responses for definitions
            Object.values(methodConfiguration.responses)
                .filter(v => v.schema && v.schema['$ref'])
                .map(v => v.schema['$ref'].replace('#/definitions/', ''))
                .forEach(ref => result[msName].definitions[ref] = apiManager.getDefinition(ref))

            // check definitions for definitions xd
            Object.values(result[msName].definitions).forEach(definition => {
                if (definition.type == 'array') {
                    let ref = definition.items.$ref.replace('#/definitions/', '')
                    result[msName].definitions[ref] = apiManager.getDefinition(ref)
                    return
                }
                if (definition.type == 'object' && definition.properties) {
                    Object.values(definition.properties).forEach(property => {
                        if (property.$ref) {
                            let ref = property.$ref.replace('#/definitions/', '')
                            result[msName].definitions[ref] = apiManager.getDefinition(ref)
                            return
                        }
                        if (property.type === 'array') {
                            let ref = property.items.$ref.replace('#/definitions/', '')
                            result[msName].definitions[ref] = apiManager.getDefinition(ref)
                            return
                        }
                    })
                    return
                }
            })

            // delete old security definition
            delete methodConfiguration['security']
        })
    })
    Object.entries(result).forEach(entry => {
        let msName = entry[0]
        let msSwaggerDefinition = entry[1]

        fs.writeFileSync('./src/private/v1/'+msName+'.yaml', YAML.stringify(msSwaggerDefinition))
        console.log(`saved ${msName}`)
    })

    console.log('Broken paths')
    console.log('============')
    brokenPaths.forEach(v => {
        console.log(v)
    })
}

main()