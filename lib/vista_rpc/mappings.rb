# frozen_string_literal: true

require_relative "data_mapper"

# Built-in stock VistA RPC response mappings.
#
# Each mapping declares the caret-delimited field positions for a specific
# RPC response format. Consumers use these to parse responses into hashes
# without hand-written split/index code.
#
# Mappings are registered in the VistaRpc::DataMapper registry and looked up
# by name:
#
#   VistaRpc::DataMapper[:patient_select].parse_one(response, extras: { dfn: 42 })
#
# Stock-VistA namespaces (ORW*/ORQQ*/TIU/XUS/XU/XM/XQAL/PSO/GMTS/...) live here.
# IHS/RPMS-only namespaces (B*/MAGG*/CIAV*) remain in the rpms-rpc gem and
# register into the same VistaRpc::DataMapper registry via the aliasing shim.
require_relative "mappings/stock_vista"
