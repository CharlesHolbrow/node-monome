'use strict'

should    = require 'should'
osc       = require 'node-osc'
makeGrid  = require '../lib/grid'

grid = null
DEVICE_PORT= 9009

# create a new grid at every descrive at current indentation level
before -> grid = makeGrid(DEVICE_PORT)
after -> grid.close()

describe 'makeGrid', ->
  describe 'width', ->
    it 'should be be null when first created', ->
      should.strictEqual grid.width, null
    it 'should throw an error on assignment', ->
      error = 'No Error' # Is there a better way?
      try grid.width = 5
      catch err then error = err
      error.should.be.an.instanceOf(Error)
    it 'should emit "listening" and listen for "size"', (done)->
      @timeout(200)
      gridB = makeGrid(DEVICE_PORT + 1)
      gridB.on 'listening', (port)->
        # pretend we are serialosc, and we are sending a size
        client = new osc.Client 'localhost', port
        client.send '/sys/size', 8, 16
        setTimeout ->
          (8).should.equal(gridB.width)
          (16).should.equal(gridB.height)
          gridB.close()
          done()
        , 10

  describe 'ready event', ->
    it 'should emit "ready" only once all 6 sys ' +
    'messages have been received', (done)->
      @timeout(200)
      gridC = makeGrid(DEVICE_PORT + 3, 'monome 64')
      gridC.on 'listening', (port)->
        client = new osc.Client 'localhost', port
        error = new Error 'grid triggered ready too soon'
        gridC.on 'ready', ->
          'm9999999'.should.equal gridC.id
          (8).should.equal gridC.width
          (8).should.equal gridC.height
          '127.0.0.1'.should.equal gridC.host
          port.should.equal gridC.port
          '/testprefix'.should.equal gridC.prefix
          (0).should.equal gridC.rotation
          done(error)

        client.send '/sys/id', 'm9999999'
        client.send '/sys/size', 8, 8
        client.send '/sys/host', '127.0.0.1'
        client.send '/sys/port', port
        client.send '/sys/prefix', '/testprefix'
        setTimeout =>
          client.send '/sys/rotation', 0
          error = null
        , 20

###
======== A Handy Little Mocha Reference ========
https://github.com/visionmedia/should.js
https://github.com/visionmedia/mocha

Mocha hooks:
  before ()-> # before describe
  after ()-> # after describe
  beforeEach ()-> # before each it
  afterEach ()-> # after each it

Should assertions:
  should.exist('hello')
  should.fail('expected an error!')
  true.should.be.ok
  true.should.be.true
  false.should.be.false

  (()-> arguments)(1,2,3).should.be.arguments
  [1,2,3].should.eql([1,2,3])
  should.strictEqual(undefined, value)
  user.age.should.be.within(5, 50)
  username.should.match(/^\w+$/)

  user.should.be.a('object')
  [].should.be.an.instanceOf(Array)

  user.should.have.property('age', 15)

  user.age.should.be.above(5)
  user.age.should.be.below(100)
  user.pets.should.have.length(5)

  res.should.have.status(200) #res.statusCode should be 200
  res.should.be.json
  res.should.be.html
  res.should.have.header('Content-Length', '123')

  [].should.be.empty
  [1,2,3].should.include(3)
  'foo bar baz'.should.include('foo')
  { name: 'TJ', pet: tobi }.user.should.include({ pet: tobi, name: 'TJ' })
  { foo: 'bar', baz: 'raz' }.should.have.keys('foo', 'bar')

  (()-> throw new Error('failed to baz')).should.throwError(/^fail.+/)

  user.should.have.property('pets').with.lengthOf(4)
  user.should.be.a('object').and.have.property('name', 'tj')
###
