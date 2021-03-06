part of collab;

//  Copyright 2011 Google Inc. All Rights Reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

/*
 * Operations modify a document.
 */
abstract class Operation extends Message {
  final String docId;
  // set when op created to the doc version of the client updated when
  // operations from this client that are ahead of this op are applied
  int docVersion;
  // set when an operation is applied by the server
  int sequence;

  Operation(String type, String senderId, this.docId, this.docVersion)
    : super(type, senderId);

  Operation.fromMap(Map<String, Object> map)
    : super.fromMap(map),
      docId = map['docId'],
      docVersion = map['docVersion'],
      sequence = map['sequence'];

  Map<String, Object> toMap([values]) => super.toMap(mergeMaps(values, {
      'docId': docId, 'docVersion': docVersion, 'sequence': sequence}));

  void apply(Document document);
}

typedef Transform(Operation op1, Operation op2);
