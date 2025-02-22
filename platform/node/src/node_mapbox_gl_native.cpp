#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-parameter"
#pragma GCC diagnostic ignored "-Wshadow"
#include <node.h>
#include <nan.h>
#pragma GCC diagnostic pop

#include "node_mapbox_gl_native.hpp"
#include "node_map.hpp"
#include "node_log.hpp"
#include "node_request.hpp"

namespace node_mbgl {

mbgl::util::RunLoop& NodeRunLoop() {
    static mbgl::util::RunLoop nodeRunLoop;
    return nodeRunLoop;
}

}

void RegisterModule(v8::Local<v8::Object> target, v8::Local<v8::Object> module) {
    // This has the effect of:
    //   a) Ensuring that the static local variable is initialized before any thread contention.
    //   b) unreffing an async handle, which otherwise would keep the default loop running.
    node_mbgl::NodeRunLoop().stop();

    node_mbgl::NodeMap::Init(target);
    node_mbgl::NodeRequest::Init(target);

    // Exports Resource constants.
    v8::Local<v8::Object> resource = Nan::New<v8::Object>();

    Nan::Set(resource,
        Nan::New("Unknown").ToLocalChecked(),
        Nan::New(mbgl::Resource::Unknown));

    Nan::Set(resource,
        Nan::New("Style").ToLocalChecked(),
        Nan::New(mbgl::Resource::Style));

    Nan::Set(resource,
        Nan::New("Source").ToLocalChecked(),
        Nan::New(mbgl::Resource::Source));

    Nan::Set(resource,
        Nan::New("Tile").ToLocalChecked(),
        Nan::New(mbgl::Resource::Tile));

    Nan::Set(resource,
        Nan::New("Glyphs").ToLocalChecked(),
        Nan::New(mbgl::Resource::Glyphs));

    Nan::Set(resource,
        Nan::New("SpriteImage").ToLocalChecked(),
        Nan::New(mbgl::Resource::SpriteImage));

    Nan::Set(resource,
        Nan::New("SpriteJSON").ToLocalChecked(),
        Nan::New(mbgl::Resource::SpriteJSON));

    Nan::Set(target,
        Nan::New("Resource").ToLocalChecked(),
        resource);

    // Make the exported object inherit from EventEmitter
    v8::Local<v8::Function> require = Nan::Get(module,
        Nan::New("require").ToLocalChecked()).ToLocalChecked().As<v8::Function>();

    v8::Local<v8::Value> eventsString = Nan::New("events").ToLocalChecked();
    v8::Local<v8::Object> events = Nan::Call(require, module, 1, &eventsString).ToLocalChecked()->ToObject();

    v8::Local<v8::Object> EventEmitter = Nan::Get(events,
        Nan::New("EventEmitter").ToLocalChecked()).ToLocalChecked()->ToObject();

    Nan::SetPrototype(target,
        Nan::Get(EventEmitter, Nan::New("prototype").ToLocalChecked()).ToLocalChecked());
    Nan::CallAsFunction(EventEmitter, target, 0, nullptr);

    mbgl::Log::setObserver(std::make_unique<node_mbgl::NodeLogObserver>(target->ToObject()));
}

NODE_MODULE(mapbox_gl_native, RegisterModule)
